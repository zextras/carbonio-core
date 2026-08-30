# Carbonio Core

Carbonio Core provides the core components and resources for the Carbonio email and collaboration platform. It ships the control scripts, libraries, configuration templates, and system services that manage Carbonio's components, including:

- Service control scripts and libraries (`zm*` utilities, configd, jython modules)
- Configuration templates (MTA, Amavis, FreshClam, configd, cron)
- System services (carbonio.target, carbonio-configd.service, carbonio-stats.service)
- Bootstrap scripts for initial setup

## Project Structure

- `src/` - Commands, libraries, and runtime utilities
- `config/` - Carbonio, MTA, configd, Amavis, FreshClam, and cron configuration
- `system/` - systemd units and operating-system integration
- `assets/` - Package assets
- `package/` - YAP packaging recipe
- `build-packages.sh` - Build script for creating the `carbonio-core` package

## Quick Start

### Prerequisites

- Docker or Podman installed
- Make

### Building Packages

```bash
# Build packages for Ubuntu 22.04
make build TARGET=ubuntu-jammy

# Build packages for Rocky Linux 9
make build TARGET=rocky-9

# Build packages for Ubuntu 24.04
make build TARGET=ubuntu-noble
```

### Supported Targets

- `ubuntu-jammy` - Ubuntu 22.04 LTS
- `ubuntu-noble` - Ubuntu 24.04 LTS
- `rocky-8` - Rocky Linux 8
- `rocky-9` - Rocky Linux 9

## Installation

The `carbonio-core` package is distributed as part of the [Carbonio platform](https://zextras.com/carbonio). To install:

### Ubuntu (Jammy/Noble)

```bash
apt-get install carbonio-core
```

### Rocky Linux (8/9)

```bash
yum install carbonio-core
```

## Contributing

We welcome contributions from the community! See [CONTRIBUTING.md](CONTRIBUTING.md) for information on how to contribute to this project.

## License

The repository contains AGPL-3.0-only, GPL-2.0-only, and CC0-1.0 components. Imported files retain their original licensing notices; license texts are provided in `LICENSES/`.
