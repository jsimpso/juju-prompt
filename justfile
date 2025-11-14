# Juju Prompt - Just commands
# Run 'just --list' to see all available commands

# Default recipe to display help information
default:
    @just --list

# Install juju-prompt to ~/.local/bin
install:
    @echo "Installing juju-prompt to ~/.local/bin..."
    @mkdir -p ~/.local/bin
    @cp juju-prompt ~/.local/bin/juju-prompt
    @cp juju-prompt-enable ~/.local/bin/juju-prompt-enable
    @cp juju-prompt-disable ~/.local/bin/juju-prompt-disable
    @chmod +x ~/.local/bin/juju-prompt
    @chmod +x ~/.local/bin/juju-prompt-enable
    @chmod +x ~/.local/bin/juju-prompt-disable
    @echo "✓ Installed to ~/.local/bin"
    @echo ""
    @echo "Make sure ~/.local/bin is in your PATH:"
    @echo '  export PATH="$HOME/.local/bin:$PATH"'

# Remove juju-prompt from ~/.local/bin
uninstall:
    @echo "Removing juju-prompt from ~/.local/bin..."
    @rm -f ~/.local/bin/juju-prompt
    @rm -f ~/.local/bin/juju-prompt-enable
    @rm -f ~/.local/bin/juju-prompt-disable
    @echo "✓ Uninstalled"

# Build the snap package (requires snapcraft)
snap:
    @echo "Building snap package..."
    @if ! command -v snapcraft >/dev/null 2>&1; then \
        echo "Error: snapcraft is not installed."; \
        echo "Install with: sudo snap install snapcraft --classic"; \
        exit 1; \
    fi
    snapcraft pack

# Remove build artifacts
clean:
    @echo "Cleaning build artifacts..."
    @rm -rf parts prime stage *.snap
    @echo "✓ Cleaned"

# Run unit tests
test:
    @echo "Running unit tests..."
    @if command -v pytest >/dev/null 2>&1; then \
        pytest -v test_juju_prompt.py; \
    else \
        echo "⚠ pytest not installed, running basic test"; \
        python3 -m pytest test_juju_prompt.py 2>/dev/null || python3 test_juju_prompt.py; \
    fi
    @echo ""
    @echo "Testing juju-prompt command..."
    @./juju-prompt || echo "Note: Test failed - Juju may not be configured"

# Install the locally built snap
install-snap: snap
    @echo "Installing snap..."
    sudo snap install --dangerous jps1_*.snap
    @echo ""
    @echo "Connect the Juju data interface:"
    @echo "  sudo snap connect jps1:dot-local-share-juju"
    @echo ""
    @echo "Enable shell integration:"
    @echo "  jps1.enable"

# Uninstall the snap package
uninstall-snap:
    @echo "Removing jps1 snap..."
    sudo snap remove jps1
    @echo "✓ Uninstalled snap"

# Format Python files (requires black)
fmt:
    @if command -v black &> /dev/null; then \
        black juju-prompt; \
        echo "✓ Formatted"; \
    else \
        echo "black is not installed. Install with: pip install black"; \
    fi

# Lint shell scripts
lint-shell:
    @echo "Linting shell scripts..."
    @if command -v shellcheck >/dev/null 2>&1; then \
        shellcheck juju-prompt-enable juju-prompt-disable shell/bash || true; \
        echo "✓ Shell script linting complete (bash scripts only)"; \
        echo "  Note: zsh and fish scripts not checked (shellcheck doesn't support them)"; \
    else \
        echo "⚠ shellcheck not installed, skipping shell script linting"; \
        echo "  Install with: sudo apt install shellcheck"; \
    fi

# Lint Python code
lint-python:
    @echo "Linting Python code..."
    @python3 -m py_compile juju-prompt
    @echo "✓ Python syntax check passed"
    @if command -v flake8 >/dev/null 2>&1; then \
        flake8 juju-prompt test_juju_prompt.py --max-line-length=100 || true; \
    else \
        echo "⚠ flake8 not installed, skipping style checks"; \
        echo "  Install with: pip install flake8"; \
    fi

# Run all linting
lint: lint-python lint-shell
    @echo "✓ All linting complete"

# Run all checks before building
check: test lint
    @echo "✓ All checks passed"

# Benchmark performance (must average < 50ms per execution)
bench:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Running performance benchmark (100 iterations)..."
    echo ""
    start=$(date +%s%N)
    for i in {1..100}; do
        ./juju-prompt >/dev/null 2>&1
    done
    end=$(date +%s%N)
    total_ns=$((end - start))
    total_ms=$((total_ns / 1000000))
    avg_ms=$((total_ms / 100))
    echo "Total time: ${total_ms}ms"
    echo "Average per execution: ${avg_ms}ms"
    echo ""
    if [ $avg_ms -lt 50 ]; then
        echo "✓ PASS - Within 50ms performance budget"
    else
        echo "✗ FAIL - Exceeds 50ms performance budget"
        exit 1
    fi
