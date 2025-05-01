UV := uv
BLUE=\033[0;34m
NC=\033[0m # No Color

# keep this aligned with GitHub actions
DOCKER_IMAGE_NAME=py-scaffolding
DOCKER_LOCAL_TAG=current-local
RUN_DOCKER_BUILD := docker buildx build --build-arg --build-arg -f Dockerfile
RUN_TRIVY := docker run  --rm -v $(shell pwd):/app ${DOCKER_IMAGE_NAME}-vulnscan:${DOCKER_LOCAL_TAG} --cache-dir ./.trivy-cache

.PHONY: \
	_install \
	_upgrade \
	all \
	build \
	build-for-tests \
	bump-major \
	bump-minor \
	bump-patch \
	check \
	check-code \
	check-fix \
	check-pre-commit \
	check-types \
	check-uv \
	clean \
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
	test-only \
	update \
	verify-packages \
	vulnscan

all: verify-packages check-fix check test doc build vulnscan ## ensure everything is OK: code checks, tests, documentation, image build, vulnerability scan

dev: check-fix check test ## daily routine to check code and run tests

verify-packages: ## check Python outdated pakcages and run a pip audit vulnerability scan
	@echo "\n${BLUE}Show outdated packages...${NC}\n"
	${UV} pip list --outdated
	@echo "\n${BLUE}auditing Python packages...${NC}\n"
	${UV} run pip-audit --desc

_install:
	@echo "\n${BLUE}Running uv lock...${NC}\n"
	${UV} run python --version
	${UV} lock --no-upgrade
	${UV} sync
	@echo "\n${BLUE}Install the pre-commit script...${NC}\n"
	${UV} run pre-commit install

_upgrade:
	${UV} sync --upgrade
	@echo "\n${BLUE}Show outdated packages...${NC}\n"
	${UV} pip list --outdated
	@echo "\n${BLUE}auditing Python packages...${NC}\n"
	${UV} run pip-audit --desc

install: _install verify-packages  ## Install the environment

upgrade: _upgrade verify-packages ## Upgrade Python libraries

check-uv: ## Verify lockfile status
	${UV} lock --check

check-fix: ## Auto fix the code issues and format code
	${UV} run ruff check --select I --fix
	${UV} run ruff format

check-code: ## Find code issues
	${UV} run ruff check
	${UV} run ruff format --preview

check-pre-commit: ## Run pre-commit against all files
	${UV} run pre-commit run --all-files

check-types: ## Just check the types with mypy
	${UV} run mypy src tests

check: check-uv check-types check-code ## Run all code checks without fixing the code

test: ## Run all the tests with code coverage. You can also `make test tests/test_my_specific.py`
	@echo "\n${BLUE}Running pytest with coverage...${NC}\n"
	${UV} run coverage erase;
	${UV} run python -Im coverage \
		run -m pytest \
		--junitxml=junit/test-results.xml \
		--hypothesis-show-statistics \
		--doctest-modules
	${UV} run coverage report
	${UV} run coverage html
	${UV} run coverage xml

test-only: ## Run a subset of the unit tests with `make test-only test_name=tests/some_file.py`
	${UV} run python -m pytest -vv --capture=fd $(test_name)

serve-coverage: ## Start a local server to show the HTML code coverage report
	@echo "\n${BLUE}Open http://localhost:8000/ \n\nKill with CTRL+C${NC}\n"
	@echo "Starting server..."
	cd "htmlcov"; ${UV} run python -OO -m http.server

doc: ## Compile and update the internal documentation
	@echo "\n${BLUE}Running Sphinx documentation...${NC}\n"
	cd docs; make html

serve-doc: doc ## Start a local server to show the internal documentation
	@echo "\n${BLUE}Open http://localhost:8000/index.html \n\nKill with CTRL+C${NC}\n"
	@echo "Starting server..."
	cd "docs/_build/html"; ${UV} run python -OO -m http.server

run-locally: ## Execute the main entry point locally (with uv)
	${UV} run python -I -OO main.py

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

bump-patch: ## bump the project's version with a PATCH
	${UV} run cz bump --increment PATCH --changelog

bump-minor: ## bump the project's version with a MINOR
	${UV} run cz bump --increment MINOR --changelog

bump-major: ## bump the project's version with a MAJOR
	${UV} run cz bump --increment MAJOR --changelog

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

help: ## Show this help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; \
		{printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
