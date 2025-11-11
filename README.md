# Juju Prompt

Display your active Juju controller and model in your shell prompt.

## Overview

`juju-prompt` is a lightweight utility that displays your current Juju controller and model, designed for integration into shell prompts. It parses the Juju configuration files (`controllers.yaml` and `models.yaml`) to determine the active context.

## Features

- **Fast execution** with minimal dependencies (Python 3 standard library only)
- **Colored output** - controller in blue, customizable model colors
- **Pattern-based coloring** - highlight production/critical models automatically
- **Toggle on/off** - `juju-prompt-on`/`juju-prompt-off` commands
- **Clean output format**: `controller:model`
- **Silent operation** when Juju is not configured
- **No external dependencies** - no YAML library required
- **Shell integration** for Bash, Zsh, and Fish
- **Snap or local installation** - works as standalone script or confined snap

## Installation

### Option 1: Snap Package (Recommended)

The easiest way to install juju-prompt is via snap:

```bash
# Install from the snap store (when published)
sudo snap install juju-prompt

# Connect the interface to access Juju data
sudo snap connect juju-prompt:dot-local-share-juju

# Enable shell integration
juju-prompt.enable
```

To disable:
```bash
juju-prompt.disable
```

### Option 2: Manual Installation

Using the provided justfile:

```bash
just install
```

This installs to `~/.local/bin/`. Ensure it's in your PATH:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

Or if you don't have [just](https://github.com/casey/just) installed:

```bash
# Manual installation
mkdir -p ~/.local/bin
cp juju-prompt juju-prompt-enable juju-prompt-disable ~/.local/bin/
chmod +x ~/.local/bin/juju-prompt*
export PATH="$HOME/.local/bin:$PATH"
```

### Option 3: Build Snap Locally

To build the snap yourself:

```bash
# Install snapcraft
sudo snap install snapcraft --classic

# Build and install the snap
just install-snap

# Or build manually
just snap
sudo snap install --dangerous juju-prompt_*.snap
sudo snap connect juju-prompt:dot-local-share-juju
```

## Usage

### Command Line

Simply run the command:

```bash
juju-prompt
```

Output format: `controller:model`

Example output:
```
jaas-ps7:dbaas-is-jaas-testing-ps7
```

### Quick Shell Integration (Snap Only)

If you installed via snap, the easiest way to enable shell integration is:

```bash
# Enable for your current shell (auto-detected)
juju-prompt.enable

# Disable if needed
juju-prompt.disable
```

The enable command will:
- Automatically detect your shell (Bash, Zsh, or Fish)
- Add the appropriate configuration to your shell's config file
- Preserve your existing prompt settings

### Manual Shell Prompt Integration

For manual installation or custom configurations:

#### Bash

Add to your `~/.bashrc`:

```bash
# Function to get Juju prompt info
juju_prompt() {
    local juju_info=$(juju-prompt 2>/dev/null)
    if [ -n "$juju_info" ]; then
        echo " [$juju_info]"
    fi
}

# Add to your PS1
PS1='[\u@\h \W$(juju_prompt)]\$ '
```

#### Zsh

Add to your `~/.zshrc`:

```zsh
# Function to get Juju prompt info
juju_prompt() {
    local juju_info=$(juju-prompt 2>/dev/null)
    if [[ -n "$juju_info" ]]; then
        echo " [$juju_info]"
    fi
}

# Add to your PROMPT
PROMPT='%n@%m %1~$(juju_prompt) %# '
```

#### Fish

Add to your `~/.config/fish/functions/fish_prompt.fish`:

```fish
function fish_prompt
    # ... your existing prompt setup ...

    set -l juju_info (juju-prompt 2>/dev/null)
    if test -n "$juju_info"
        echo -n " [$juju_info]"
    end

    # ... rest of your prompt ...
end
```

## Color Customization

juju-prompt supports customizable colors based on model name patterns. This is useful for visually highlighting critical or production environments.

### Configuration File

- **Snap installation**: `~/snap/juju-prompt/common/colors.conf`
- **Local installation**: `~/.config/juju-prompt/colors.conf`

The configuration file is auto-created on first run with sensible defaults.

### Format

```
# Pattern:Color
^production.*:red
.*critical.*:bright_red
^staging.*:yellow
^dev|test.*:green
```

### Available Colors

Standard colors: `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`

Bright colors: `bright_black`, `bright_red`, `bright_green`, `bright_yellow`, `bright_blue`, `bright_magenta`, `bright_cyan`, `bright_white`

### Pattern Matching

- Patterns are regular expressions matched against the model name
- First match wins (order matters)
- Lines starting with `#` are comments
- Controller is always displayed in blue

### Example

```bash
# Highlight production models in red
^production.*:red

# Critical models in bright red
.*critical.*:bright_red

# Staging in yellow
^staging.*:yellow

# Dev and test in green
^(dev|test).*:green
```

## Toggling the Prompt

Once shell integration is enabled, you can toggle the prompt on/off:

```bash
juju-prompt-on           # Enable for current session
juju-prompt-off          # Disable for current session
juju-prompt-off -g       # Disable globally (persists)
juju-prompt-on -g        # Re-enable globally
```

The global disable/enable creates or removes `~/.juju/juju-ps1/disabled` marker file.

## Environment Variables

- `JUJU_DATA`: Custom location for Juju configuration files (default: `~/.local/share/juju`)
  - **Note**: This only works with local installation. When installed as a snap, the tool can only access `~/.local/share/juju` due to strict confinement.
- `JUJU_PROMPT_DEBUG`: Set to `1` to enable debug output

## How It Works

The utility reads two key files from your Juju data directory:

1. `controllers.yaml` - contains the `current-controller` field
2. `models.yaml` - contains the `current-model` field for each controller

It uses simple line-by-line parsing for maximum performance, avoiding dependencies on external YAML libraries.

### Snap Permissions

When installed as a snap, juju-prompt uses the `personal-files` interface to access `~/.local/share/juju` (the same approach used by the Juju snap itself). This requires manual connection after installation:

```bash
sudo snap connect juju-prompt:dot-local-share-juju
```

This is a security feature of snap confinement - applications must explicitly request access to user data outside their sandbox.

## Requirements

- Python 3.6 or higher
- Juju CLI configured with at least one controller

## Development

This project uses [just](https://github.com/casey/just) as a command runner. To see all available commands:

```bash
just --list
```

### Available Commands

**Installation:**
- `just install` - Install to ~/.local/bin
- `just uninstall` - Remove from ~/.local/bin
- `just snap` - Build snap package
- `just install-snap` - Build and install snap
- `just uninstall-snap` - Remove snap

**Testing & Quality:**
- `just test` - Run unit tests
- `just lint` - Run all linting (Python + shell)
- `just lint-python` - Lint Python code only
- `just lint-shell` - Lint shell scripts only (requires shellcheck)
- `just check` - Run all checks (test + lint)
- `just fmt` - Format Python code with black

**Build:**
- `just clean` - Remove build artifacts

### Running Tests

```bash
# Run unit tests
just test

# Run all linting
just lint

# Run everything
just check
```

## License

This utility is designed for use with [Juju](https://juju.is/), the Multi-Cloud Application Orchestration tool.