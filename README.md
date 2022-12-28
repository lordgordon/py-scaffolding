# py-scaffolding
My custom Python project scaffolding repository: https://github.com/lordgordon/py-scaffolding.

Docker images published at https://hub.docker.com/repository/docker/lordgordon/py-scaffolding.

---

![pr-validation](https://github.com/lordgordon/py-scaffolding/workflows/pr-validation/badge.svg?branch=main)
[![release](https://github.com/lordgordon/py-scaffolding/actions/workflows/release.yaml/badge.svg)](https://github.com/lordgordon/py-scaffolding/actions/workflows/release.yaml)

## Requirements and setup

- Python 3.11 (`pip3` must be available) with installed globally:
  - [Poetry](https://python-poetry.org) installed globally.
  - [pre-commit](https://pre-commit.com) installed globally.
- Linux/UNIX compatible system with `make` command.
- [Docker](https://www.docker.com/).

Then, to set everything up on macOS:
```sh
brew install python@3.11 pre-commit
pip3 install poetry
pre-commit install
make
```

:point_right: **Note**: `brew` does not automatically link `python3` to the newest Python version when it could breaks
dependencies. To force this, at your own risk, one could add to its `.zshrc`:

```bash
# Python Homebrew
current_python="3.11";
current_python_path="/usr/local/opt/python@${current_python}";
export PATH="${current_python_path}/bin:$PATH";
export LDFLAGS="-L${current_python}/lib";

# force current_python to overcome brew not linking newest Python version
alias wheel3="${current_python_path}/bin/wheel${current_python}";
alias python3="${current_python_path}/bin/python${current_python}";
alias pip3="${current_python_path}/bin/pip${current_python}";
alias pydoc3="${current_python_path}/bin/pydoc${current_python}";
alias 2to3="${current_python_path}/bin/2to3-${current_python}";
alias idle="${current_python_path}/bin/idle${current_python}";
alias python3-config="${current_python_path}/bin/python${current_python}-config";
```

### Configure VS Code
Run the following commands:
```sh
mkdir .vscode;touch .vscode/settings.json
```

Then put the following JSON in `.vscode/settings.json` and replace the `python.pythonPath` value with the output of
`poetry env info -p`, adding `/bin/python` at the end:
```json
{
  "python.pythonPath": "/path/to/poetry/env/bin/python",
  "python.poetryPath": "poetry",
  "python.linting.pylintEnabled": true,
  "python.linting.enabled": true
}
```

Install the [EditorConfig](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig)
extension to take advantage of `.editorconfig`.

## Release and Changelog

Version bump and changelog update:
```sh
# PATCH
poetry run cz bump --increment PATCH -ch --dry-run
# MINOR
poetry run cz bump --increment MINOR -ch --dry-run
# MAJOR
poetry run cz bump --increment MAJOR -ch --dry-run
```

If OK, run again without `--dry-run`. For full details see
https://commitizen-tools.github.io/commitizen/bump/

## Commands

The main command that run everything (full clean excluded):
```sh
make
```

Then, to execute the main entry point with the local Poetry environment:
```sh
make run-locally
```

or open a shell in the Docker image:
```shell
make run-shell
```

`make help` to the rescue in case of doubts.

### Run the production image

To run the main entry point with the production image, first build the production image:
```sh
make build
```

Then:
```sh
docker run --rm -it py-scaffolding:current-local
```

### Serving commands
| command | description |
| :-- | :-- |
| `make serve-coverage` | Start a local server to show the HTML code coverage report. |
| `make serve-doc` | Start a local server to show the internal documentation. |

### Helpful commands
| command | description |
| :-- | :-- |
| `make update` | Just update the environment. |
| `make autolint` | Autolinting code. |
| `make lint-base` | Code linting without running autolinters. |
| `make lint` | Autolint and code linting. |
| `make test` | Run all the tests with code coverage. You can also `make test tests/test_my_specific.py`. |
| `make doc` | Compile and update the internal documentation. |
| `make clean` | Force a clean environment: remove all temporary files and caches. Start from a new environment. This command allow to start over from a fresh state. |
| `make build` | Build the Docker image. |
| `make run-locally` | Execute the main entry point locally (with Poetry). |
| `make run-shell` | Open a shell in the Docker image. |
