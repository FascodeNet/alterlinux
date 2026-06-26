# CLAUDE.md

<!-- LLM Generated: This file was created by Claude (claude.ai/code) -->

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**AlterLinux** is an Arch Linux-derived OS optimized for Japanese users. **AlterISO 6.0** (in the `dev` branch) is the build system that generates ISO images using a profile generation approach. It creates archiso-compatible profiles from AlterISO configuration files and uses an "Injectable" mechanism to hook into archiso functions without modifying upstream code.

## Build Commands

```bash
# Generate archiso profile from AlterISO config
./alteriso/gen.sh configs/<profile_name>

# Build ISO image (generates profile + runs mkarchiso)
cd alteriso && ./build.sh

# Or directly with Go
go run ./src profile build configs/<profile_name>

# Clean generated profiles
./alteriso/clean.sh

# Lint shell scripts
make check
```

Build requires root privileges. Output goes to `alteriso/out/`, work directory is `alteriso/work/`.

## Architecture

### Core Components

- **Go Application** (`alteriso/src/`): Profile generation using Cobra CLI
  - `internal/cmd/` - CLI commands (root, profile generate, profile build)
  - `internal/archiso/` - Profile parsing, generation, and Injectable handling
- **Modules** (`alteriso/modules/`): Pluggable units providing packages, files, scripts, and injection hooks
- **Bootloaders** (`alteriso/bootloaders/`): BIOS/UEFI boot configuration templates
- **archiso** (`archiso/`): Forked upstream archiso with Injectable support

### Data Flow

1. User provides `configs/<profile>/profiledef.json` + `profiledef.sh`
2. Go tool reads JSON, loads referenced modules from `modules/` directory
3. Modules provide: packages, files, scripts, injection hooks
4. AlterISO merges everything → generates archiso-compatible profile in `out/`
5. mkarchiso builds ISO with injected hooks

### Injectable Mechanism

AlterISO leverages archiso's `_run_once()` function which sources `profiledef.sh`. Generated `profiledef.sh` includes:

- Pre/post hooks: `pre_<function>()`, `post_<function>()`
- Override hooks: `override_<function>()`
- Example: `post__make_packages()`, `pre__make_customize_airootfs()`

### Module Structure

```
modules/<name>/
├── alteriso.json           # Module manifest (required)
├── module.sh               # Shell script with hook functions
├── packages.x86_64.d/      # Package lists
├── airootfs.any/           # Files for all architectures
└── airootfs.x86_64/        # Architecture-specific files
```

### Profile Configuration

`profiledef.json` fields:

- `arch` (required): Target architecture (currently "x86_64")
- `modules` (required): List of modules to load in order
- `os_name`, `kernel_name`, `username`, `cow_spacesize`: Optional config
- `injects`: Profile-level injection hooks
- `require_injectable`: Whether profile needs Injectable archiso support

Placeholders in bootloader configs: `%ALTERISO_OS_NAME%`, `%ALTERISO_KERNEL_NAME%`, `%ALTERISO_COW_SPACESIZE%`, `%ALTERISO_KERNEL_PARAM%`

## Key Files

- `alteriso/src/internal/archiso/profile_gen.go` - Main profile generation logic
- `alteriso/src/internal/archiso/injects/profiledef.sh.in` - Template for generated profiledef.sh
- `alteriso/src/internal/archiso/injects/injecter.sh` - Hook injection mechanism
- `alteriso/configs/xfce/profiledef.json` - Example profile configuration

## Important Notes

- Module load order matters: determines precedence for injections and file overwrites
- Scripts rebuild Go binary each time; binaries are cleaned up after
- Documentation is primarily in Japanese (see `alteriso/docs/`)
- Testing is done by building ISO and running with qemu (`scripts/run_archiso.sh`)
- Changes to archiso upstream may require updates to injection templates

## LLM-Generated Content Rules

This project distinguishes between LLM-generated and human-written code. When creating new files or making substantial changes, follow these rules:

### Marking New Files

Add an LLM marker comment at the top of new files:

- **Markdown files**: `<!-- LLM Generated: Created by Claude -->`
- **Go files**: `// LLM Generated: Created by Claude`
- **Shell scripts**: `# LLM Generated: Created by Claude`
- **JSON files**: Add `"_llm_generated": "Created by Claude"` field

### Marking Existing File Changes

When making substantial changes to existing files, add a comment near the modified code:

```go
// LLM Modified: Added error handling - Claude
```

```bash
# LLM Modified: Refactored validation logic - Claude
```

### Git Commit Messages

Include the Co-Authored-By trailer in commit messages:

```
Co-Authored-By: Claude <noreply@anthropic.com>
```
