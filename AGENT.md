# AI Agent Instructions for jps1

## Core Philosophy

This is a **shell prompt utility** - it runs on every single prompt render. Performance and simplicity are non-negotiable.

### Guiding Principles

1. **Speed above all else** - This executes hundreds of times per day per user
2. **Simplicity is elegance** - Don't overcomplicate solutions
3. **Test all logic** - Every code path must have test coverage
4. **Explain decisions** - Before implementing, explain your reasoning
5. **Fail silently** - Shell prompts must never show errors or delay the user

## Critical Constraints

### No External Dependencies
**Why**: Installing PyYAML or similar adds 50-200ms of import time alone. Users will notice lag in their prompt.

**Implication**: We parse YAML manually using line-by-line string operations. This is intentional, not a oversight to "fix."

### Performance Budget: < 50ms
Measure with `time ./juju-prompt`. Anything slower becomes noticeable user friction.

**What this means**:
- No subprocess calls to `juju` CLI (100-500ms)
- No regex compilation in hot paths (compile once, reuse)
- Minimal file I/O (read only what's needed)
- No defensive imports "just in case"

### Silent Failure Model
If Juju isn't configured or files are missing: exit silently with no output.

**Why**: A shell prompt that prints errors is broken. Users can't easily dismiss or fix them mid-session.

**Exception**: Debug mode (`JUJU_PROMPT_DEBUG=1`) prints to stderr for troubleshooting.

## Non-Obvious Design Decisions

### Custom YAML Parser
We don't use a real YAML parser - we read line-by-line looking for specific patterns:
- `current-controller: value`
- `current-model: value` (under the right controller section)

**Why this works**: Juju's YAML structure is stable and simple for these fields.

**Limitation**: This would break with complex YAML features (anchors, multi-line strings). But Juju doesn't use those for these fields.

### Dual Path System (Snap vs Local)
The code has two parallel path resolution systems:

**Juju data** (read-only):
- Check `JUJU_DATA` env var (local only)
- Check `SNAP_REAL_HOME` (snap gets actual home, not confined home)
- Fallback to `~/.local/share/juju`

**Config/disable files** (writable):
- Check `SNAP_USER_COMMON` (snap's writable persistent storage)
- Fallback to `~/.config/juju-prompt/`

**Why**: Snap strict confinement means you can't just access arbitrary paths. The `personal-files` interface gives access to Juju data, but snap's own config goes to a different location.

**Testing**: Always test both code paths (snap and local) for any path-related changes.

## Testing Requirements

### Every Logic Path Must Be Tested
If you add a function, add tests. If you add a conditional, test both branches.

**Examples of required test coverage**:
- File exists vs file missing
- Valid YAML vs malformed YAML
- Pattern matches vs no match
- Snap environment vs local environment
- Debug mode on vs off

### Run Tests Before Committing
```bash
just check  # Runs tests + linting
```

If tests fail, the change is not complete.

## Decision-Making Process

Before implementing changes:

1. **Explain your reasoning** - Why is this the right approach?
2. **Consider performance** - Will this slow down prompt rendering?
3. **Check simplicity** - Is there a simpler solution?
4. **Identify tests needed** - What test cases will validate this?

Only after explaining and getting alignment, proceed with implementation.

## Common Pitfalls to Avoid

### "Let's just use PyYAML/ruamel.yaml"
No. Import time alone violates the performance budget. The custom parser is intentional.

### "Let's call `juju` CLI for accuracy"
No. A subprocess call adds 100-500ms. We parse config files for speed.

### "We should warn users about invalid config"
No. Shell prompts fail silently. Use debug mode for troubleshooting, not runtime warnings.

### "This regex pattern should be case-insensitive by default"
Consider performance. `re.IGNORECASE` has overhead. Is it worth it for this use case?

### Adding features without tests
All logic must be tested. No exceptions.

## Debugging Workflow

When something isn't working:

1. Enable debug mode: `JUJU_PROMPT_DEBUG=1 ./juju-prompt`
2. Check actual file paths and content
3. Test parsing logic in isolation
4. Verify both snap and local code paths

For snap issues specifically:
```bash
# Check if interface is connected
snap connections jps1

# Verify file access
sudo ls -la ~/.local/share/juju/
```

## Shell Integration Considerations

Each shell (bash/zsh/fish) has different syntax but same requirements:
- Check if disabled (session or global)
- Call `juju-prompt` silently (redirect stderr to /dev/null)
- Only output if result is non-empty
- Provide toggle functions (on/off with optional -g flag)

When adding support for a new shell, maintain this pattern.

## What This File Is NOT

- **Not a user manual** - That's README.md
- **Not a code tutorial** - Read the code, it's straightforward
- **Not a task list** - That's the justfile
- **Not a style guide** - Follow PEP 8, run `just lint`

This file exists to explain **why** decisions were made, so you don't "fix" things that are intentionally designed this way.
