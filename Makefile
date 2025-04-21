UV := uv
BLUE=\033[0;34m
NC=\033[0m # No Color

# keep this aligned with GitHub actions
DOCKER_IMAGE_NAME=py-scaffolding
DOCKER_LOCAL_TAG=current-local
RUN_DOCKER_BUILD := docker buildx build --build-arg --build-arg -f Dockerfile
RUN_TRIVY := docker run  --rm -v $(shell pwd):/app ${DOCKER_IMAGE_NAME}-vulnscan:${DOCKER_LOCAL_TAG} --cache-dir ./.trivy-cache

.PHONY: \
	all \
	autolint \
	build \
	build-for-tests \
	clean \
	doc \
	help \
	lint \
	lint-base \
	lint-mypy \
	pre-commit-all \
	run \
	run-locally \
	run-shell-prod \
	run-shell-testing \
	serve-coverage \
	serve-doc \
	test \
	update \
	uv-check \
	vulnscan

all: lint test doc build-for-tests build vulnscan

update: ## Just update the environment
	@echo "\n${BLUE}Running uv lock...${NC}\n"
	@${UV} run python --version
	@${UV} lock --no-upgrade
	@${UV} sync
	@echo "\n${BLUE}Install the pre-commit script...${NC}\n"
	@${UV} run pre-commit install
	@echo "\n${BLUE}Show outdated packages...${NC}\n"
	@${UV} pip list --outdated
	@echo "\n${BLUE}auditing Python packages...${NC}\n"
	@${UV} run pip-audit --desc

uv-check: ## Verify uv lockfile status
	@${UV} lock --check

autolint: ## Autolinting code
	@echo "\n${BLUE}Running autolinting...${NC}\n"
	@${UV} run black .
	@${UV} run isort .
	@${UV} run pyupgrade --py311-plus main.py $(shell find src -name "*.py") $(shell find tests -name "*.py")

pre-commit-all:
	@${UV} run pre-commit run --all-files

lint-mypy: ## Just run mypy
	@echo "\n${BLUE}Running mypy...${NC}\n"
	@${UV} run mypy src tests

lint-base: uv-check lint-mypy ## Just run the linters without autolinting
	@echo "\n${BLUE}Running bandit...${NC}\n"
	@${UV} run bandit -r src
	@echo "\n${BLUE}Running pylint...${NC}\n"
	@${UV} run pylint src tests
	@echo "\n${BLUE}Running doc8...${NC}\n"
	@${UV} run python -m doc8 docs

lint: autolint pre-commit-all lint-base ## Autolint and code linting

test: ## Run all the tests with code coverage. You can also `make test tests/test_my_specific.py`
	@echo "\n${BLUE}Running pytest with coverage...${NC}\n"
	@${UV} run coverage erase;
	@${UV} run python -Im coverage \
		run -m pytest \
		--junitxml=junit/test-results.xml \
		--hypothesis-show-statistics \
		--doctest-modules
	@${UV} run coverage report
	@${UV} run coverage html
	@${UV} run coverage xml

serve-coverage: ## Start a local server to show the HTML code coverage report
	@echo "\n${BLUE}Open http://localhost:8000/ \n\nKill with CTRL+C${NC}\n"
	@echo "Starting server..."
	@cd "htmlcov"; ${UV} run python -OO -m http.server

doc: ## Compile and update the internal documentation
	@echo "\n${BLUE}Running Sphinx documentation...${NC}\n"
	@cd docs; make html

serve-doc: doc ## Start a local server to show the internal documentation
	@echo "\n${BLUE}Open http://localhost:8000/index.html \n\nKill with CTRL+C${NC}\n"
	@echo "Starting server..."
	@cd "docs/_build/html"; ${UV} run python -OO -m http.server

clean: ## Force a clean environment: remove all temporary files and caches. Start from a new environment
	@echo "\n${BLUE}Cleaning up...${NC}\n"
	-rm -rf .mypy_cache .pytest_cache htmlcov junit coverage.xml .coverage .hypothesis dist .trivy-cache
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "__pycache__" -delete
	-cd docs; make clean
	@echo "\n${BLUE}Removing uv environment...${NC}\n"
	-rm -rf .venv
	-docker image rm ${DOCKER_IMAGE_NAME}:${DOCKER_LOCAL_TAG} --force
	-docker image rm ${DOCKER_IMAGE_NAME}-testing:${DOCKER_LOCAL_TAG} --force
	-docker image rm ${DOCKER_IMAGE_NAME}-vulnscan:${DOCKER_LOCAL_TAG} --force
	-docker image rm ${DOCKER_IMAGE_NAME}-migrations:${DOCKER_LOCAL_TAG} --force

run-locally: ## Execute the main entry point locally (with uv)
	@${UV} run python -I -OO main.py

build-for-tests: ## Build Docker image with testing tools
	${RUN_DOCKER_BUILD} --target testing -t ${DOCKER_IMAGE_NAME}-testing:${DOCKER_LOCAL_TAG} .

build: build-for-tests ## Build Docker image for production
	${RUN_DOCKER_BUILD} --target production -t ${DOCKER_IMAGE_NAME}:${DOCKER_LOCAL_TAG} .
	${RUN_DOCKER_BUILD} --target migrations -t ${DOCKER_IMAGE_NAME}-migrations:${DOCKER_LOCAL_TAG} .

run: build ## Execute the main entry point in the Docker image
	docker run --rm -it ${DOCKER_IMAGE_NAME}:${DOCKER_LOCAL_TAG}

run-shell-testing: build-for-tests ## Open a shell in the testing Docker image
	docker run  --rm --entrypoint /bin/bash -it ${DOCKER_IMAGE_NAME}-testing:${DOCKER_LOCAL_TAG}

run-shell-prod: build ## Open a shell in the production Docker image
	docker run  --rm --entrypoint /bin/bash -it ${DOCKER_IMAGE_NAME}:${DOCKER_LOCAL_TAG}

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
