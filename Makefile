BLUE=\033[0;34m
NC=\033[0m # No Color

# keep this aligned with GitHub actions
DOCKER_IMAGE_NAME ?= py-scaffolding
DOCKER_LOCAL_TAG ?= current-local
COMPOSE_YAML ?= docker-compose.yaml
DOCKER_PLATFORM ?= linux/amd64

UV_GIT_LFS := 1
UV := uv
UV_RUN := uv run --locked
RUN_DOCKER_BUILD := docker buildx build --platform ${DOCKER_PLATFORM} --build-arg --build-arg

ARCH := $(shell uname -m)

.PHONY: \
	_install \
	_upgrade \
	all \
	build \
	build-for-prod \
	build-for-tests \
	check \
	check-ci \
	check-code \
	check-fix \
	check-pre-commit \
	check-types \
	check-uv \
	clean \
	compose-force-reset \
	compose-logs \
	compose-start \
	compose-stop \
	dev \
	doc \
	help \
	install \
	run \
	run-locally \
	run-shell-prod \
	run-shell-testing \
	serve-coverage \
	serve-doc \
	test \
	test-ci \
	test-only \
	update \
	verify-packages

all: verify-packages check-fix check test doc build ## ensure everything is OK: code checks, tests, documentation, image build, vulnerability scan

dev: check-fix check test ## daily routine to check code and run tests

verify-packages: ## check Python outdated packages and run a pip audit vulnerability scan
	@echo "\n${BLUE}Show outdated packages...${NC}\n"
	${UV} tree --outdated --locked
	@echo "\n${BLUE}auditing Python packages...${NC}\n"
	${UV_RUN} pip-audit --desc

_install:
	@echo "\n${BLUE}Running uv lock...${NC}\n"
	${UV} lock --no-upgrade
	${UV} sync --locked
	@echo "\n${BLUE}Install the pre-commit script...${NC}\n"
	${UV_RUN} pre-commit install
	${UV_RUN} python --version

_upgrade:
	${UV} sync --upgrade

install: _install verify-packages  ## Install the environment

upgrade: _upgrade verify-packages ## Upgrade Python libraries

check-uv: ## Verify lockfile status
	${UV} lock --check

check-fix: ## Auto fix the code issues and format code
	${UV_RUN} ruff check --select I --fix
	${UV_RUN} ruff format

check-code: ## Find code issues
	${UV_RUN} ruff check
	${UV_RUN} ruff format --preview

check-pre-commit: ## Run pre-commit against all files
	${UV_RUN} pre-commit run --all-files

check-types: ## Just check the types with mypy
	${UV_RUN} mypy src tests

check: check-uv check-pre-commit check-types check-code ## Run all code checks without fixing the code

check-ci: check-uv check-types check-code ## Run code checks for the CI/CD environment

test-local: ## Run all the tests with code coverage. You can also `make test tests/test_my_specific.py`
	@echo "\n${BLUE}Running pytest with coverage...${NC}\n"
	${UV_RUN} coverage erase;
	${UV_RUN} python -Im coverage \
		run -m pytest \
		--junitxml=junit/test-results.xml \
		--hypothesis-show-statistics \
		--doctest-modules
	${UV_RUN} coverage report
	${UV_RUN} coverage html
	${UV_RUN} coverage xml

test: test-local ## Full test with compose requirements

test-only: ## Run a subset of the unit tests with `make test-only test_name=tests/some_file.py`
	${UV_RUN} python -m pytest -vv --capture=fd $(test_name)

test-ci: ## Run tests for CICD
	docker run --rm --network volta-connect-edge-middleware_middleware-network ${DOCKER_IMAGE_NAME}-testing:${DOCKER_LOCAL_TAG} make test-local

serve-coverage: ## Start a local server to show the HTML code coverage report
	@echo "\n${BLUE}Open http://localhost:8000/ \n\nKill with CTRL+C${NC}\n"
	@echo "Starting server..."
	cd "htmlcov"; ${UV_RUN} python -OO -m http.server

doc: ## Compile and update the internal documentation
	@echo "\n${BLUE}Running Sphinx documentation...${NC}\n"
	cd docs; make html

serve-doc: doc ## Start a local server to show the internal documentation
	@echo "\n${BLUE}Open http://localhost:8000/index.html \n\nKill with CTRL+C${NC}\n"
	@echo "Starting server..."
	cd "docs/_build/html"; ${UV_RUN} python -OO -m http.server

run-locally: ## Execute the main entry point locally (with uv)
	${UV_RUN} python -I -OO main.py

build-for-tests: ## Build Docker image with testing tools
	${RUN_DOCKER_BUILD} -f Dockerfile --target testing -t ${DOCKER_IMAGE_NAME}-testing:${DOCKER_LOCAL_TAG} .

build-for-prod: ## Build Docker image for production
	${RUN_DOCKER_BUILD} -f Dockerfile --target production -t ${DOCKER_IMAGE_NAME}:${DOCKER_LOCAL_TAG} .

build: build-for-tests build-for-prod ## Build all docker images

run-shell-testing: build-for-tests ## Open a shell in the testing Docker image
	docker run --rm --entrypoint /bin/bash -it ${DOCKER_IMAGE_NAME}-testing:${DOCKER_LOCAL_TAG}
  # --network <network name>

run-shell-prod: build ## Open a shell in the production Docker image
	docker run --rm --entrypoint /bin/bash -it ${DOCKER_IMAGE_NAME}:${DOCKER_LOCAL_TAG}
  # --network <network name>

compose-start: build-for-tests ## Run the docker compose with local config with the existing images
	docker-compose -f ${COMPOSE_YAML} up --detach

compose-logs: ## Follow the logs from all running containers
	docker-compose -f ${COMPOSE_YAML} logs --follow --timestamps

compose-stop: ## Stop the docker compose without removing the containers
	docker-compose -f ${COMPOSE_YAML} stop

compose-force-reset: ## Remove all persistent data, including databases, allowing to restart from scratch
	docker-compose -f ${COMPOSE_YAML} down

clean: ## Force a clean environment: remove all temporary files and caches. Start from a new environment
	@echo "\n${BLUE}Cleaning up...${NC}\n"
	-rm -rf .mypy_cache .pytest_cache htmlcov junit coverage.xml .coverage .hypothesis dist .trivy-cache
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "__pycache__" -delete
	-cd docs; make clean
	@echo "\n${BLUE}Removing uv environment...${NC}\n"
	${UV} cache clean
	-rm -rf .venv
	-docker image rm ${DOCKER_IMAGE_NAME}:${DOCKER_LOCAL_TAG} --force
	-docker image rm ${DOCKER_IMAGE_NAME}-testing:${DOCKER_LOCAL_TAG} --force

help: ## Show this help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; \
		{printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
