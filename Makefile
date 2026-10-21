SHELL := /bin/sh

COMPOSE := docker compose
ENV_FILE := .env

.DEFAULT_GOAL := help

.PHONY: help init up down shell logs migrate ensure-env validate-env detach-template

help: ## Show the available commands
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  %-18s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ensure-env ## Create Laravel, start services, and run initial migrations
	@set -eu; \
	if find src -mindepth 1 -maxdepth 1 ! -name .empty -print -quit | grep -q .; then \
		echo "src already contains files; initialization will not overwrite an application." >&2; \
		exit 1; \
	fi; \
	rm -f src/.empty; \
	echo "Building the PHP image..."; \
	$(COMPOSE) build php; \
	echo "Creating the Laravel application..."; \
	$(COMPOSE) run --rm --no-deps php composer create-project --no-scripts laravel/laravel .; \
	if [ ! -f src/.env ]; then cp src/.env.example src/.env; fi; \
	echo "Starting services..."; \
	$(COMPOSE) up -d --wait; \
	echo "Discovering Laravel packages..."; \
	$(COMPOSE) exec -T php composer run-script post-autoload-dump; \
	echo "Generating the Laravel application key..."; \
	$(COMPOSE) exec -T php php artisan key:generate --force; \
	echo "Running initial migrations..."; \
	$(COMPOSE) exec -T php php artisan migrate --force; \
	project_name="$$(sed -n 's/^PROJECT_NAME=//p' $(ENV_FILE) | tail -n 1)"; \
	sed "s/{{PROJECT_NAME}}/$$project_name/g" templates/README.project.md > README.md; \
	rm -rf templates; \
	echo "Laravel is ready at http://127.0.0.1:$$(sed -n 's/^HTTP_PORT=//p' $(ENV_FILE) | tail -n 1)"; \
	remote="$$(git remote get-url origin 2>/dev/null || true)"; \
	normalized="$$(printf '%s\n' "$$remote" | sed -E 's#^git@github\\.com:#github.com/#; s#^ssh://git@github\\.com/#github.com/#; s#^https?://github\\.com/#github.com/#; s#\\.git/?##')"; \
	normalized="$${normalized%/}"; \
	if [ "$$normalized" = "github.com/eliseumarmon/laravel-init" ]; then \
		echo "Direct clone detected. To start independent Git history, run: make detach-template CONFIRM_DETACH=YES"; \
	fi

up: validate-env ## Start all services and wait until they are ready
	@$(COMPOSE) up -d --wait

down: validate-env ## Stop services without deleting the database volume
	@$(COMPOSE) down

shell: validate-env ## Open a shell in the PHP container
	@$(COMPOSE) exec php bash

logs: validate-env ## Follow service logs
	@$(COMPOSE) logs -f

migrate: validate-env ## Run Laravel migrations
	@$(COMPOSE) exec -T php php artisan migrate

ensure-env: ## Create .env from the example when it does not exist
	@if test ! -f $(ENV_FILE); then \
		host_uid="$$(id -u)"; \
		host_gid="$$(id -g)"; \
		sed -e "s/^HOST_UID=.*/HOST_UID=$$host_uid/" -e "s/^HOST_GID=.*/HOST_GID=$$host_gid/" .env.example > $(ENV_FILE); \
		echo "Created .env from .env.example with HOST_UID=$$host_uid and HOST_GID=$$host_gid."; \
	fi
	@$(MAKE) --no-print-directory validate-env

validate-env: ## Validate the local Docker Compose configuration
	@test -f $(ENV_FILE) || { echo "Missing .env. Copy .env.example to .env first." >&2; exit 1; }
	@set -eu; \
	project_name="$$(sed -n 's/^PROJECT_NAME=//p' $(ENV_FILE) | tail -n 1)"; \
	case "$$project_name" in \
		''|[!a-z0-9]*|*[!a-z0-9_-]*) echo "PROJECT_NAME must start with a lowercase letter or number and use only lowercase letters, numbers, hyphens, or underscores." >&2; exit 1;; \
	esac; \
	for key in HTTP_PORT MYSQL_PORT; do \
		value="$$(sed -n "s/^$$key=//p" $(ENV_FILE) | tail -n 1)"; \
		case "$$value" in ''|*[!0-9]*) echo "$$key must be a numeric port." >&2; exit 1;; esac; \
		[ "$$value" -ge 1 ] && [ "$$value" -le 65535 ] || { echo "$$key must be between 1 and 65535." >&2; exit 1; }; \
	done

detach-template: ## Replace a direct clone's Laravel Init history (CONFIRM_DETACH=YES required)
	@set -eu; \
	if [ "$(CONFIRM_DETACH)" != "YES" ]; then \
		echo "This removes the inherited Git history. Re-run with CONFIRM_DETACH=YES." >&2; \
		exit 1; \
	fi; \
	git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "This directory is not a Git worktree." >&2; exit 1; }; \
	remote="$$(git remote get-url origin 2>/dev/null || true)"; \
	normalized="$$(printf '%s\n' "$$remote" | sed -E 's#^git@github\.com:#github.com/#; s#^ssh://git@github\.com/#github.com/#; s#^https?://github\.com/#github.com/#; s#\.git/?##')"; \
	normalized="$${normalized%/}"; \
	[ "$$normalized" = "github.com/eliseumarmon/laravel-init" ] || { echo "origin is not the Laravel Init template; refusing to replace Git history." >&2; exit 1; }; \
	base_ref="$$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || printf '%s' origin/main)"; \
	git rev-parse --verify "$$base_ref" >/dev/null 2>&1 || { echo "Cannot verify the template's tracked branch; refusing to replace Git history." >&2; exit 1; }; \
	[ "$$(git rev-list --count "$$base_ref..HEAD")" -eq 0 ] || { echo "Local commits were detected; refusing to replace Git history." >&2; exit 1; }; \
	echo "Removing only the inherited Git metadata; your working files will be preserved..."; \
	rm -rf .git; \
	git init -b main; \
	echo "New Git repository created. Review the files, then run: git add -A && git commit -m 'Initial Laravel application'"
