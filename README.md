# Carbonio Core

Carbonio Core is an open-source, community-driven email server that provides core components and resources for the Carbonio email and collaboration platform. This project contains the essential infrastructure, configuration files, and system services that power Carbonio's mail delivery and management capabilities, including:

- Core mail server components
- System services (carbonio.target, carbonio-configd.service, carbonio-stats.service)
- Configuration management
- Bootstrap scripts for initial setup

## Project Structure

- `ce/` - Community Edition specific files
- `core/` - Core package files and configurations
- `webui/` - Web UI related files
- `build-packages.sh` - Build script for creating distribution packages

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

These packages are distributed as part of the [Carbonio platform](https://zextras.com/carbonio). To install:

### Ubuntu (Jammy/Noble)

```bash
apt-get install <package-name>
```

### Rocky Linux (8/9)

```bash
yum install <package-name>
```

## Contributing

We welcome contributions from the community! See [CONTRIBUTING.md](CONTRIBUTING.md) for information on how to contribute to this project.

## License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE.md](LICENSE.md) file for details.
