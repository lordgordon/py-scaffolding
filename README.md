# py-scaffolding
My custom Python project scaffolding repository: https://github.com/lordgordon/py-scaffolding.

Docker images published at https://hub.docker.com/repository/docker/lordgordon/py-scaffolding.

---

![pr-validation](https://github.com/lordgordon/py-scaffolding/workflows/pr-validation/badge.svg?branch=main)
[![release](https://github.com/lordgordon/py-scaffolding/actions/workflows/release.yaml/badge.svg)](https://github.com/lordgordon/py-scaffolding/actions/workflows/release.yaml)

## Requirements and setup

- [brew](https://brew.sh/).
- Linux/UNIX compatible system with `make` command.
- [Docker](https://www.docker.com/).

Then, to set everything up on macOS:
```sh
brew install pyenv
pyenv install
make
```

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
| command               | description                                                 |
|:----------------------|:------------------------------------------------------------|
| `make serve-coverage` | Start a local server to show the HTML code coverage report. |
| `make serve-doc`      | Start a local server to show the internal documentation.    |

### Helpful commands
| command            | description                                                                                                                                          |
|:-------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------|
| `make update`      | Just update the environment.                                                                                                                         |
| `make autolint`    | Autolinting code.                                                                                                                                    |
| `make lint-base`   | Code linting without running autolinters.                                                                                                            |
| `make lint`        | Autolint and code linting.                                                                                                                           |
| `make test`        | Run all the tests with code coverage. You can also `make test tests/test_my_specific.py`.                                                            |
| `make doc`         | Compile and update the internal documentation.                                                                                                       |
| `make clean`       | Force a clean environment: remove all temporary files and caches. Start from a new environment. This command allow to start over from a fresh state. |
| `make build`       | Build the Docker image.                                                                                                                              |
| `make run-locally` | Execute the main entry point locally (with Poetry).                                                                                                  |
| `make run-shell`   | Open a shell in the Docker image.                                                                                                                    |
