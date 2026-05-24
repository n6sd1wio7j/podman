# Makefile for podman
# See docs/make.md for documentation on make targets

export GOPROXY ?= https://proxy.golang.org

GO ?= go
GOFLAGS ?= -trimpath
GO_LDFLAGS := $(shell if $(GO) version|grep -q gccgo ; then echo "-gccgoflags"; else echo "-ldflags"; fi)
GO_GCFLAGS := $(shell if $(GO) version|grep -q gccgo ; then echo "-gccgoflags"; else echo "-gcflags"; fi)

PACKAGE := github.com/containers/podman
BINDIR ?= ${PREFIX}/bin
LIBEXECDIR ?= ${PREFIX}/libexec
MANDIR ?= ${PREFIX}/share/man
SHAREDIR ?= ${PREFIX}/share
BUILD_DIR ?= _output
OBJ_DIR ?= $(BUILD_DIR)/obj
BIN_DIR ?= $(BUILD_DIR)/bin

# Version information
GIT_COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_TAG ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
BUILD_DATE ?= $(shell date -u '+%Y-%m-%dT%H:%M:%SZ')

LDFLAGS := -X $(PACKAGE)/libpod/define.gitCommit=$(GIT_COMMIT) \
		   -X $(PACKAGE)/libpod/define.buildInfo=$(BUILD_DATE)

# Default target
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

.PHONY: all
all: binaries ## Build all binaries

.PHONY: binaries
binaries: podman podman-remote ## Build podman and podman-remote binaries

.PHONY: podman
podman: $(BIN_DIR) ## Build the podman binary
	$(GO) build $(GOFLAGS) $(GO_LDFLAGS) "$(LDFLAGS)" -o $(BIN_DIR)/$@ ./cmd/podman

.PHONY: podman-remote
podman-remote: $(BIN_DIR) ## Build the podman-remote binary
	$(GO) build $(GOFLAGS) $(GO_LDFLAGS) "$(LDFLAGS)" -tags remote -o $(BIN_DIR)/$@ ./cmd/podman

.PHONY: test
test: unit-test ## Run all tests

.PHONY: unit-test
unit-test: ## Run unit tests
	$(GO) test -v ./...

.PHONY: integration-test
integration-test: ## Run integration tests
	$(GO) test -v -tags integration ./test/...

.PHONY: lint
lint: ## Run linters
	golangci-lint run ./...

.PHONY: fmt
fmt: ## Format Go source code
	$(GO) fmt ./...

.PHONY: vet
vet: ## Run go vet
	$(GO) vet ./...

.PHONY: vendor
vendor: ## Update vendored dependencies
	$(GO) mod tidy
	$(GO) mod vendor

.PHONY: clean
clean: ## Remove build artifacts
	rm -rf $(BUILD_DIR)
	rm -f podman podman-remote

.PHONY: install
install: binaries ## Install podman binaries
	install -d -m 755 $(DESTDIR)$(BINDIR)
	install -m 755 $(BIN_DIR)/podman $(DESTDIR)$(BINDIR)/podman

.PHONY: uninstall
uninstall: ## Uninstall podman binaries
	rm -f $(DESTDIR)$(BINDIR)/podman
	rm -f $(DESTDIR)$(BINDIR)/podman-remote

$(BIN_DIR):
	mkdir -p $@
