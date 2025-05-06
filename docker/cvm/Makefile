# Makefile for docker/cvm

.PHONY: help up down build restart logs ps update

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

up: ## Bring up all services in detached mode
	@for file in docker-compose*.yml; do \
		docker compose -f $$file up -d; \
	done

down: ## Bring down all services
	@for file in docker-compose*.yml; do \
		docker compose -f $$file down; \
	done

build: ## Build all services
	@for file in docker-compose*.yml; do \
		docker compose -f $$file build; \
	done

restart: ## Restart all services
	@for file in docker-compose*.yml; do \
		docker compose -f $$file restart; \
	done

logs: ## Show logs for all services
	@for file in docker-compose*.yml; do \
		docker compose -f $$file logs; \
	done

ps: ## List running services
	@for file in docker-compose*.yml; do \
		docker compose -f $$file ps; \
	done

update: ## Update all services (pull, down, up, remove old images)
	@for file in docker-compose*.yml; do \
		echo "Updating services in $${file}..."; \
		docker compose -f $${file} pull; \
		docker compose -f $${file} down --remove-orphans -v; \
		docker compose -f $${file} up -d; \
		docker image prune -f; \
	done

lobechat-up: ## Bring up LobeChat service in detached mode
	docker compose -f docker-compose-lobechat.yml up -d

lobechat-down: ## Bring down LobeChat service
	docker compose -f docker-compose-lobechat.yml down

lobechat-build: ## Build LobeChat service
	docker compose -f docker-compose-lobechat.yml build

lobechat-restart: ## Restart LobeChat service
	docker compose -f docker-compose-lobechat.yml restart

lobechat-logs: ## Show logs for LobeChat service
	docker compose -f docker-compose-lobechat.yml logs -f

lobechat-ps: ## List LobeChat service status
	docker compose -f docker-compose-lobechat.yml ps

owui-up: ## Bring up Open WebUI service in detached mode
	docker compose -f docker-compose-owui.yml up -d

owui-down: ## Bring down Open WebUI service
	docker compose -f docker-compose-owui.yml down

owui-build: ## Build Open WebUI service
	docker compose -f docker-compose-owui.yml build

owui-restart: ## Restart Open WebUI service
	docker compose -f docker-compose-owui.yml restart

owui-logs: ## Show logs for Open WebUI service
	docker compose -f docker-compose-owui.yml logs -f

owui-ps: ## List Open WebUI service status
	docker compose -f docker-compose-owui.yml ps