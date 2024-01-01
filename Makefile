POETRY := python3 -m poetry
BLUE=\033[0;34m
NC=\033[0m # No Color

# keep this aligned with GitHub actions
DOCKER_BASE_IMAGE=python:3.11.7-slim-bullseye
PYSETUP_PATH=/app
DOCKER_IMAGE_NAME=py-scaffolding
DOCKER_LOCAL_TAG=current-local
RUN_DOCKER_BUILD := docker buildx build --platform linux/amd64 --build-arg DOCKER_BASE_IMAGE=${DOCKER_BASE_IMAGE} --build-arg PYSETUP_PATH=${PYSETUP_PATH} -f Dockerfile
RUN_TRIVY := docker run --platform linux/amd64 --rm -v $(shell pwd):/app ${DOCKER_IMAGE_NAME}-vulnscan:${DOCKER_LOCAL_TAG} --cache-dir ./.trivy-cache

.PHONY: all autolint build build-for-tests clean doc help lint lint-base lint-mypy poetry-check pre-commit-all \
				run-locally run-shell serve-coverage serve-doc test update vulnscan

all: lint test doc build-for-tests build vulnscan

update: ## Just update the environment
	@echo "\n${BLUE}Update poetry itself and check...${NC}\n"
	pip3 install --upgrade poetry pre-commit
	@${POETRY} check
	@${POETRY} run python --version
	@echo "\n${BLUE}Running poetry update...${NC}\n"
	@${POETRY} update pip setuptools
	@${POETRY} lock --no-update
	@${POETRY} install
	@echo "\n${BLUE}Show outdated packages...${NC}\n"
	@${POETRY} show -o
	@echo "\n${BLUE}pre-commit hook install and run...${NC}\n"
	pre-commit install
	@echo "\n${BLUE}auditing Python packages...${NC}\n"
	@${POETRY} run pip-audit --desc

poetry-check: ## Verify Poetry lockfile status
	@${POETRY} check --lock

autolint: ## Autolinting code
	@echo "\n${BLUE}Running autolinting...${NC}\n"
	@${POETRY} run black .
	@${POETRY} run isort .
	@${POETRY} run pyupgrade --py311-plus main.py $(shell find py_scaffolding -name "*.py") $(shell find tests -name "*.py")

pre-commit-all:
	pre-commit run --all-files

lint-mypy: ## Just run mypy
	@echo "\n${BLUE}Running mypy...${NC}\n"
	@${POETRY} run mypy py_scaffolding tests

lint-base: poetry-check lint-mypy ## Just run the linters without autolinting
	@echo "\n${BLUE}Running bandit...${NC}\n"
	@${POETRY} run bandit -r py_scaffolding
	@echo "\n${BLUE}Running pylint...${NC}\n"
	@${POETRY} run pylint py_scaffolding tests
	@echo "\n${BLUE}Running doc8...${NC}\n"
	@${POETRY} run python -m doc8 docs

lint: autolint pre-commit-all lint-base ## Autolint and code linting

test: ## Run all the tests with code coverage. You can also `make test tests/test_my_specific.py`
	@echo "\n${BLUE}Running pytest with coverage...${NC}\n"
	@${POETRY} run coverage erase;
	@${POETRY} run coverage run -m pytest \
		--junitxml=junit/test-results.xml \
		--hypothesis-show-statistics \
		--doctest-modules
	@${POETRY} run coverage report
	@${POETRY} run coverage html
	@${POETRY} run coverage xml

serve-coverage: ## Start a local server to show the HTML code coverage report
	@echo "\n${BLUE}Open http://localhost:8000/ \n\nKill with CTRL+C${NC}\n"
	@echo "Starting server..."
	@cd "htmlcov"; ${RUN_POETRY} python -OO -m http.server

doc: ## Compile and update the internal documentation
	@echo "\n${BLUE}Running Sphinx documentation...${NC}\n"
	@cd docs; make html

serve-doc: doc ## Start a local server to show the internal documentation
	@echo "\n${BLUE}Open http://localhost:8000/ \n\nKill with CTRL+C${NC}\n"
	@echo "Starting server..."
	@cd "docs/_build/html"; ${RUN_POETRY} python -OO -m http.server

clean: ## Force a clean environment: remove all temporary files and caches. Start from a new environment
	@echo "\n${BLUE}Cleaning up...${NC}\n"
	-rm -rf .mypy_cache .pytest_cache htmlcov junit coverage.xml .coverage .hypothesis dist .trivy-cache
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "__pycache__" -delete
	-cd docs; make clean
	@echo "\n${BLUE}Removing poetry environment...${NC}\n"
	-rm -rf .venv
	-docker image rm ${DOCKER_IMAGE_NAME}:${DOCKER_LOCAL_TAG} --force
	-docker image rm ${DOCKER_IMAGE_NAME}-testing:${DOCKER_LOCAL_TAG} --force
	-docker image rm ${DOCKER_IMAGE_NAME}-vulnscan:${DOCKER_LOCAL_TAG} --force
	-docker image rm ${DOCKER_IMAGE_NAME}-migrations:${DOCKER_LOCAL_TAG} --force
	-docker image rm ${DOCKER_BASE_IMAGE}

run-locally: ## Execute the main entry point locally (with Poetry)
	@${POETRY} run python -OO main.py

run-shell: build ## Open a shell in the Docker image
	docker run --rm -it ${DOCKER_IMAGE_NAME}:${DOCKER_LOCAL_TAG} /bin/bash

build-for-tests: ## Build Docker image with testing tools
	docker pull ${DOCKER_BASE_IMAGE}
	${RUN_DOCKER_BUILD} --target testing -t ${DOCKER_IMAGE_NAME}-testing:${DOCKER_LOCAL_TAG} .

build: build-for-tests ## Build Docker image for production
	${RUN_DOCKER_BUILD} --target production -t ${DOCKER_IMAGE_NAME}:${DOCKER_LOCAL_TAG} .
	${RUN_DOCKER_BUILD} --target migrations -t ${DOCKER_IMAGE_NAME}-migrations:${DOCKER_LOCAL_TAG} .

vulnscan: ## Execute Trivy scanner dockerized against this repo
	## IMPORTANT: GitHub actions runs Trivy natively, you need to update the workflow when changing options here
	${RUN_DOCKER_BUILD} --target vulnscan -t ${DOCKER_IMAGE_NAME}-vulnscan:${DOCKER_LOCAL_TAG} .
	${RUN_TRIVY} version
	${RUN_TRIVY} config --config trivy.yaml .
	${RUN_TRIVY} fs --config trivy.yaml .
	${RUN_TRIVY} rootfs --config trivy.yaml /

help: ## Show this help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; \
		{printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
