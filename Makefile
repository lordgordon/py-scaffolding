RUN_POETRY := poetry run
BLUE=\033[0;34m
NC=\033[0m # No Color

# keep this aligned with GitHub actions
DOCKER_BASE_IMAGE=python:3.11.1-slim-bullseye
PYSETUP_PATH=/app
DOCKER_IMAGE_NAME=py-scaffolding
DOCKER_LOCAL_TAG=current-local
RUN_DOCKER_BUILD := docker build --build-arg DOCKER_BASE_IMAGE=${DOCKER_BASE_IMAGE} --build-arg PYSETUP_PATH=${PYSETUP_PATH} -f Dockerfile
RUN_TRIVY := docker run --rm -v $(shell pwd):/app ${DOCKER_IMAGE_NAME}-vulnscan:${DOCKER_LOCAL_TAG} --cache-dir ./.trivy-cache

.PHONY: all update autolint lint-mypy lint-base lint test doc serve-doc serve-coverage clean help build vulnscan run-locally run-shell build-for-tests

all: update lint test doc build-for-tests build vulnscan

update: ## Just update the environment
	@echo "\n${BLUE}Update poetry itself and check...${NC}\n"
	pip3 install --upgrade poetry
	poetry check
	@echo "\n${BLUE}Running poetry update...${NC}\n"
	@${RUN_POETRY} pip install --upgrade pip setuptools
	@${RUN_POETRY} python --version
	poetry update
	@echo "\n${BLUE}Show outdated packages...${NC}\n"
	@${RUN_POETRY} pip list -o --not-required --outdated
	@echo "\n${BLUE}pre-commit hook install and run...${NC}\n"
	cp -f pre-commit.sh .git/hooks/pre-commit
	@${RUN_POETRY} pip-audit --desc --ignore-vuln PYSEC-2022-42969
# see https://github.com/pytest-dev/pytest/issues/10392

autolint: ## Autolinting code
	@echo "\n${BLUE}Running autolinting...${NC}\n"
	@${RUN_POETRY} black .
	@${RUN_POETRY} isort .
	@${RUN_POETRY} pyupgrade --py39-plus main.py $(shell find py_scaffolding -name "*.py") $(shell find tests -name "*.py")

lint-mypy: ## Just run mypy
	@echo "\n${BLUE}Running mypy...${NC}\n"
	@${RUN_POETRY} mypy py_scaffolding tests

lint-base: lint-mypy ## Just run the linters without autolinting
	@echo "\n${BLUE}Running bandit...${NC}\n"
# @${RUN_POETRY} bandit -r py_scaffolding
	@echo "\n${BLUE}Running pylint...${NC}\n"
	@${RUN_POETRY} pylint py_scaffolding tests
	@echo "\n${BLUE}Running doc8...${NC}\n"
	@${RUN_POETRY} doc8 docs

lint: autolint lint-base ## Autolint and code linting

test: ## Run all the tests with code coverage. You can also `make test tests/test_my_specific.py`
	@echo "\n${BLUE}Running pytest with coverage...${NC}\n"
	@${RUN_POETRY} coverage erase;
	@${RUN_POETRY} coverage run -m pytest \
		--junitxml=junit/test-results.xml \
		--hypothesis-show-statistics \
		--doctest-modules
	@${RUN_POETRY} coverage report
	@${RUN_POETRY} coverage html
	@${RUN_POETRY} coverage xml

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
	poetry env list
	poetry env info -p
	poetry env remove $(shell poetry run which python)
	poetry env list
	-docker image rm ${DOCKER_IMAGE_NAME}:${DOCKER_LOCAL_TAG} --force
	-docker image rm ${DOCKER_IMAGE_NAME}-testing:${DOCKER_LOCAL_TAG} --force
	-docker image rm ${DOCKER_IMAGE_NAME}-vulnscan:${DOCKER_LOCAL_TAG} --force
	-docker image rm ${DOCKER_IMAGE_NAME}-migrations:${DOCKER_LOCAL_TAG} --force
	-docker image rm ${DOCKER_BASE_IMAGE}

run-locally: ## Execute the main entry point locally (with Poetry)
	@${RUN_POETRY} python -OO main.py

run-shell: ## Open a shell in the Docker image
	docker run --rm -it ${DOCKER_IMAGE_NAME}:${DOCKER_LOCAL_TAG} /bin/bash

build-for-tests: ## Build Docker image with testing tools
	docker pull ${DOCKER_BASE_IMAGE}
	${RUN_DOCKER_BUILD} --target testing -t ${DOCKER_IMAGE_NAME}-testing:${DOCKER_LOCAL_TAG} .

build: ## Build Docker image for production
	${RUN_DOCKER_BUILD} --target production -t ${DOCKER_IMAGE_NAME}:${DOCKER_LOCAL_TAG} .
	${RUN_DOCKER_BUILD} --target migrations -t ${DOCKER_IMAGE_NAME}-migrations:${DOCKER_LOCAL_TAG} .

vulnscan: ## Execute Trivy scanner dockerized against this repo
	## IMPORTANT: GitHub actions runs Trivy natively, you need to update the workflow when changing options here
	${RUN_DOCKER_BUILD} --target vulnscan -t ${DOCKER_IMAGE_NAME}-vulnscan:${DOCKER_LOCAL_TAG} .
	${RUN_TRIVY} version
	${RUN_TRIVY} conf --exit-code 1 --severity HIGH,CRITICAL .
	${RUN_TRIVY} fs --exit-code 1 --ignore-unfixed --severity HIGH,CRITICAL --no-progress .
	${RUN_TRIVY} rootfs --exit-code 1 --ignore-unfixed --vuln-type "os,library" --security-checks "vuln,config" --no-progress /

help: ## Show this help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; \
		{printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
