SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help
CLUSTER_NAME ?= mini-data-ml-platform
PROFILE ?= core

.PHONY: help check validate bootstrap cluster-up cluster-status platform-up apps-build deploy seed smoke-test demo platform-down

help: ## Show stable project entry points
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z0-9_-]+:.*## / {printf "%-18s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check: ## Check required and optional local tools
	@./scripts/check-tools.sh

validate: ## Run fast offline validation
	@./scripts/validate.sh

bootstrap: check cluster-up ## Check tools and create the kind cluster

cluster-up: ## Create the named kind cluster idempotently
	@CLUSTER_NAME=$(CLUSTER_NAME) ./scripts/create-cluster.sh

cluster-status: ## Show nodes for this project's cluster
	@kubectl --context kind-$(CLUSTER_NAME) get nodes

platform-up: ## Apply scaffolded shared platform resources
	@PROFILE=$(PROFILE) CLUSTER_NAME=$(CLUSTER_NAME) ./scripts/platform-up.sh

apps-build: validate ## Test and build pinned local app images
	@./scripts/build-images.sh

deploy: ## Apply the GitOps bootstrap manifest
	@CLUSTER_NAME=$(CLUSTER_NAME) ./scripts/deploy.sh

seed: ## Emit deterministic transaction fixtures (SEED_COUNT defaults to 10)
	@SEED_COUNT=$${SEED_COUNT:-10} python3 apps/transaction-producer/app/main.py

smoke-test: ## Check workloads and API health with bounded waits
	@CLUSTER_NAME=$(CLUSTER_NAME) ./tests/smoke/end_to_end.sh

demo: seed smoke-test ## Seed and verify the current profile

platform-down: ## Delete only the explicitly named kind cluster
	@CLUSTER_NAME=$(CLUSTER_NAME) ./scripts/delete-cluster.sh

