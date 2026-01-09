# Makefile for Stage0 Runbook Template
# Simple curl-based commands for testing runbooks
# 
# Customize this Makefile for your organization:
# 1. Update CONTAINER_IMAGE to your GHCR image name
# 2. Adjust API_URL if using a different port or host
# 3. Add any custom commands your team needs

.PHONY: help dev down open validate execute get-token container deploy

# Configuration - CUSTOMIZE THESE FOR YOUR ORG
CONTAINER_IMAGE ?= ghcr.io/YOUR_ORG/YOUR_RUNBOOKS_IMAGE:latest
API_URL ?= http://localhost:8083
RUNBOOK ?= 
ENV ?= 

help:
	@echo "Available commands:"
	@echo "  make dev              - Start API in dev mode with local runbooks mounted"
	@echo "  make down             - Stop all services"
	@echo "  make open             - Open web UI in browser"
	@echo "  make validate         - Validate a runbook (requires RUNBOOK=path/to/runbook.md)"
	@echo "  make execute          - Execute a runbook (requires RUNBOOK=path/to/runbook.md)"
	@echo "  make container        - Build container with your runbooks"
	@echo "  make deploy           - Deploy using packaged runbooks"
	@echo ""
	@echo "Examples:"
	@echo "  make dev"
	@echo "  make validate RUNBOOK=./runbooks/MyRunbook.md"
	@echo "  make execute RUNBOOK=./runbooks/MyRunbook.md ENV='VAR1=value1 VAR2=value2'"
	@echo "  make container"
	@echo "  make deploy"

dev:
	@echo "Starting Stage0 Runbook API in dev mode..."
	@docker-compose -f samples/docker-compose.dev.yaml up -d
	@echo "Waiting for API to be ready..."
	@timeout 30 bash -c 'until curl -sf http://localhost:8083/metrics > /dev/null; do sleep 1; done' || true
	@echo "API is ready at http://localhost:8083"
	@echo "Web UI is available at http://localhost:8084"

down:
	@docker-compose -f samples/docker-compose.dev.yaml down

open:
	@echo "Opening web UI..."
	@open http://localhost:8084 2>/dev/null || xdg-open http://localhost:8084 2>/dev/null || echo "Please open http://localhost:8084 in your browser"

get-token:
	@curl -s -X POST $(API_URL)/dev-login \
		-H "Content-Type: application/json" \
		-d '{"subject": "dev-user", "roles": ["developer", "admin"]}' \
		| jq -r '.access_token // .token // empty'

validate:
	@if [ -z "$(RUNBOOK)" ]; then \
		echo "Error: RUNBOOK is required. Example: make validate RUNBOOK=./runbooks/MyRunbook.md"; \
		exit 1; \
	fi
	@echo "Validating $(RUNBOOK)..."
	@TOKEN=$$(make -s get-token); \
	if [ -z "$$TOKEN" ]; then \
		echo "Error: Failed to get authentication token. Is the API running? Run 'make dev' first."; \
		exit 1; \
	fi; \
	FILENAME=$$(basename $(RUNBOOK)); \
	if [ -n "$(ENV)" ]; then \
		QUERY="?$$(echo '$(ENV)' | sed 's/ /\\&/g')"; \
	else \
		QUERY=""; \
	fi; \
	curl -s -X PATCH "$(API_URL)/api/runbooks/$$FILENAME$$QUERY" \
		-H "Authorization: Bearer $$TOKEN" \
		-H "Content-Type: application/json" \
		| jq '.' || cat

execute:
	@if [ -z "$(RUNBOOK)" ]; then \
		echo "Error: RUNBOOK is required. Example: make execute RUNBOOK=./runbooks/MyRunbook.md"; \
		exit 1; \
	fi
	@echo "Executing $(RUNBOOK)..."
	@TOKEN=$$(make -s get-token); \
	if [ -z "$$TOKEN" ]; then \
		echo "Error: Failed to get authentication token. Is the API running? Run 'make dev' first."; \
		exit 1; \
	fi; \
	FILENAME=$$(basename $(RUNBOOK)); \
	if [ -n "$(ENV)" ]; then \
		QUERY="?$$(echo '$(ENV)' | sed 's/ /\\&/g')"; \
	else \
		QUERY=""; \
	fi; \
	curl -s -X POST "$(API_URL)/api/runbooks/$$FILENAME$$QUERY" \
		-H "Authorization: Bearer $$TOKEN" \
		-H "Content-Type: application/json" \
		| jq '.' || cat

# Build container with your runbooks
container:
	@echo "Building container image: $(CONTAINER_IMAGE)"
	@docker build -f Dockerfile -t $(CONTAINER_IMAGE) .
	@echo "Built: $(CONTAINER_IMAGE)"

# Deploy using packaged runbooks
deploy:
	@echo "Deploying with packaged runbooks..."
	@sed "s|ghcr.io/YOUR_ORG/YOUR_RUNBOOKS_IMAGE:latest|$(CONTAINER_IMAGE)|g" \
		samples/docker-compose.prod.yaml > docker-compose.prod.yaml
	@docker-compose -f docker-compose.prod.yaml up -d
	@echo "Deployment complete. API at http://localhost:8083, UI at http://localhost:8084"
