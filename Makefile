POETRY_RUN := poetry run
BLUE=\033[0;34m
NC=\033[0m # No Color

.PHONY: all update autolint lint-mypy lint test doc serve-doc serve-coverage clean help

all: update lint test doc

update: ## Just update the environment
	@echo "\n${BLUE}Update poetry itself and check...${NC}\n"
	pip3 install --upgrade poetry
	poetry check
	@echo "\n${BLUE}Running poetry update...${NC}\n"
	@${POETRY_RUN} pip install --upgrade pip setuptools
	@${POETRY_RUN} python --version
	poetry update
	@echo "\n${BLUE}Show outdated packages...${NC}\n"
	@${POETRY_RUN} pip list -o --not-required --outdated
	@echo "\n${BLUE}pre-commit hook install and run...${NC}\n"
	cp -f pre-commit.sh .git/hooks/pre-commit

autolint: ## Autolinting code
	@echo "\n${BLUE}Running autolinting...${NC}\n"
	@${POETRY_RUN} black .
	@${POETRY_RUN} isort .
	@${POETRY_RUN} pyupgrade --py39-plus main.py $(shell find py_scaffolding -name "*.py") $(shell find tests -name "*.py")

lint-mypy:
	@echo "\n${BLUE}Running mypy...${NC}\n"
	@${POETRY_RUN} mypy py_scaffolding tests

lint: autolint lint-mypy ## Autolint and code linting
	@echo "\n${BLUE}Running bandit...${NC}\n"
	@${POETRY_RUN} bandit -c bandit.yaml -r .
	@echo "\n${BLUE}Running pylint...${NC}\n"
	@${POETRY_RUN} pylint py_scaffolding tests
	@echo "\n${BLUE}Running doc8...${NC}\n"
	@${POETRY_RUN} doc8 docs

test: ## Run all the tests with code coverage. You can also `make test tests/test_my_specific.py`
	@echo "\n${BLUE}Running pytest with coverage...${NC}\n"
	@${POETRY_RUN} coverage erase;
	@${POETRY_RUN} coverage run -m pytest \
		--junitxml=junit/test-results.xml \
		--hypothesis-show-statistics \
		--doctest-modules
	@${POETRY_RUN} coverage report
	@${POETRY_RUN} coverage html
	@${POETRY_RUN} coverage xml

serve-coverage: ## Start a local server to show the HTML code coverage report
	@echo "\n${BLUE}Open http://localhost:8000/ \n\nKill with CTRL+C${NC}\n"
	@echo "Starting server..."
	@cd "htmlcov"; ${POETRY_RUN} python -m http.server

doc: ## Compile and update the internal documentation
	@echo "\n${BLUE}Running Sphinx documentation...${NC}\n"
	@cd docs; make html

serve-doc: doc ## Start a local server to show the internal documentation
	@echo "\n${BLUE}Open http://localhost:8000/ \n\nKill with CTRL+C${NC}\n"
	@echo "Starting server..."
	@cd "docs/_build/html"; ${POETRY_RUN} python -m http.server

clean: ## Force a clean environment: remove all temporary files and caches. Start from a new environment
	@echo "\n${BLUE}Cleaning up...${NC}\n"
	rm -rf .mypy_cache .pytest_cache htmlcov junit coverage.xml .coverage .hypothesis
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "__pycache__" -delete
	cd docs; make clean
	@echo "\n${BLUE}Removing poetry environment...${NC}\n"
	poetry env list
	poetry env info -p
	poetry env remove $(shell poetry run which python)
	poetry env list

run: ## Execute the main entry point
	@${POETRY_RUN} python main.py

help: ## Show this help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; \
		{printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
