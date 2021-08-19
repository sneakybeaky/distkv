# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

compile: protoc-gen protoc-gen-rpc ## generate the protobuf code
	protoc api/v1/*.proto \
		--plugin=$(PROTOC_GEN) \
		--plugin=$(PROTOC_GEN_RPC) \
		--go_out=. \
		--go-grpc_out=. \
		--go_opt=paths=source_relative \
		--go-grpc_opt=paths=source_relative \
		--proto_path=.

PROTOC_GEN = $(shell pwd)/bin/protoc-gen-go
protoc-gen: ## Download protoc-gen-go locally if necessary.
	$(call go-get-tool,$(PROTOC_GEN),google.golang.org/protobuf/cmd/protoc-gen-go@v1.27.1)

PROTOC_GEN_RPC = $(shell pwd)/bin/protoc-gen-go-grpc
protoc-gen-rpc: ## Download protoc-gen-go-rpc locally if necessary.
	$(call go-get-tool,$(PROTOC_GEN_RPC),google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.1)


# go-get-tool will 'go get' any package $2 and install it to $1.
PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
define go-get-tool
@[ -f $(1) ] || { \
set -e ;\
echo "Downloading $(2)" ;\
GOBIN=$(PROJECT_DIR)/bin go install $(2) ;\
}
endef
