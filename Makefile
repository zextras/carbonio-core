.DEFAULT_GOAL := help

# Available distributions for building
DISTROS := ubuntu-focal ubuntu-jammy ubuntu-noble rocky-8 rocky-9
YAP_VERSION := 1.11
YAP_FLAGS := -sdc

.PHONY: help
help: ## Show this help message
	@echo "Carbonio Core - Available Make Commands"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Available distributions for build:"
	@echo "  - ubuntu-focal (Ubuntu 20.04 LTS)"
	@echo "  - ubuntu-jammy (Ubuntu 22.04 LTS)"
	@echo "  - ubuntu-noble (Ubuntu 24.04 LTS)"
	@echo "  - rocky-8      (Rocky Linux 8)"
	@echo "  - rocky-9      (Rocky Linux 9)"

.PHONY: build-ubuntu-focal
build-ubuntu-focal: ## Build packages for Ubuntu 20.04 (Focal)
	@echo "Building for Ubuntu Focal..."
	podman run -ti \
		--workdir /project \
		-v "$(shell pwd):/project" \
		"docker.io/m0rf30/yap-ubuntu-focal:$(YAP_VERSION)" \
		build ubuntu-focal /project $(YAP_FLAGS)

.PHONY: build-ubuntu-jammy
build-ubuntu-jammy: ## Build packages for Ubuntu 22.04 (Jammy)
	@echo "Building for Ubuntu Jammy..."
	podman run -ti \
		--workdir /project \
		-v "$(shell pwd):/project" \
		"docker.io/m0rf30/yap-ubuntu-jammy:$(YAP_VERSION)" \
		build ubuntu-jammy /project $(YAP_FLAGS)

.PHONY: build-ubuntu-noble
build-ubuntu-noble: ## Build packages for Ubuntu 24.04 (Noble)
	@echo "Building for Ubuntu Noble..."
	podman run -ti \
		--workdir /project \
		-v "$(shell pwd):/project" \
		"docker.io/m0rf30/yap-ubuntu-noble:$(YAP_VERSION)" \
		build ubuntu-noble /project $(YAP_FLAGS)

.PHONY: build-rocky-8
build-rocky-8: ## Build packages for Rocky Linux 8
	@echo "Building for Rocky Linux 8..."
	podman run -ti \
		--workdir /project \
		-v "$(shell pwd):/project" \
		"docker.io/m0rf30/yap-rocky-8:$(YAP_VERSION)" \
		build rocky-8 /project $(YAP_FLAGS)

.PHONY: build-rocky-9
build-rocky-9: ## Build packages for Rocky Linux 9
	@echo "Building for Rocky Linux 9..."
	podman run -ti \
		--workdir /project \
		-v "$(shell pwd):/project" \
		"docker.io/m0rf30/yap-rocky-9:$(YAP_VERSION)" \
		build rocky-9 /project $(YAP_FLAGS)

.PHONY: build-all
build-all: ## Build packages for all supported distributions
	@echo "Building for all distributions..."
	@$(MAKE) build-ubuntu-focal
	@$(MAKE) build-ubuntu-jammy
	@$(MAKE) build-ubuntu-noble
	@$(MAKE) build-rocky-8
	@$(MAKE) build-rocky-9

.PHONY: clean
clean: ## Clean build artifacts
	@echo "Cleaning artifacts..."
	rm -rf artifacts/
	@echo "Clean complete."

.PHONY: check-podman
check-podman: ## Check if podman is installed
	@which podman > /dev/null || (echo "Error: podman is not installed. Please install podman first." && exit 1)
	@echo "podman is installed: $$(podman --version)"

.PHONY: validate
validate: ## Validate the project structure and configuration
	@echo "Validating project structure..."
	@test -f yap.json || (echo "Error: yap.json not found" && exit 1)
	@test -f build-packages.sh || (echo "Error: build-packages.sh not found" && exit 1)
	@test -d core || (echo "Error: core/ directory not found" && exit 1)
	@echo "Project structure validation passed."
