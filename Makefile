POETRY_RUN := poetry run 
BLUE=\033[0;34m
NC=\033[0m # No Color

all: update autolint lint test
.PHONY: all

update:
	@echo "\n${BLUE}Update poetry itself and check...${NC}\n"
	pip3 install --upgrade poetry
	poetry check
	@echo "\n${BLUE}Running poetry update...${NC}\n"
	@${POETRY_RUN} pip install --upgrade pip setuptools
	@${POETRY_RUN} python --version
	poetry update
	@echo "\n${BLUE}Show outdated packages...${NC}\n"
	@${POETRY_RUN} pip list -o --not-required --outdated

autolint:
	@echo "\n${BLUE}Running autolinting...${NC}\n"
	@${POETRY_RUN} black .
	@${POETRY_RUN} isort .

lint:
	@echo "\n${BLUE}Running mypy...${NC}\n"
	@${POETRY_RUN} mypy .
	@echo "\n${BLUE}Running bandit...${NC}\n"
	@${POETRY_RUN} bandit -c bandit.yaml -r .
	@echo "\n${BLUE}Running pylint...${NC}\n"
	@${POETRY_RUN} pylint src tests

test:
	@echo "\n${BLUE}Running pytest with coverage...${NC}\n"
	@${POETRY_RUN} coverage erase;
	@${POETRY_RUN} coverage run -m pytest --junitxml=junit/test-results.xml
	@${POETRY_RUN} coverage report
	@${POETRY_RUN} coverage html
	@${POETRY_RUN} coverage xml

clean:
	@echo "\n${BLUE}Cleaning up...${NC}\n"
	rm -rf .mypy_cache .pytest_cache htmlcov junit coverage.xml .coverage
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "__pycache__" -delete
	@echo "\n${BLUE}Removing poetry environment...${NC}\n"
	poetry env list
	poetry env info -p
	poetry env remove $(shell poetry run which python)
	poetry env list
