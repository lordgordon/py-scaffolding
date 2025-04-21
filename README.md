# py-scaffolding
My custom Python project scaffolding repository: https://github.com/lordgordon/py-scaffolding.

Docker images published at https://hub.docker.com/repository/docker/lordgordon/py-scaffolding.

:point_right: Note: to release the project as a Python library, you need to run `uv build` and add the proper ci/cd
to publish the library.

---

![pr-validation](https://github.com/lordgordon/py-scaffolding/workflows/pr-validation/badge.svg?branch=main)
[![release](https://github.com/lordgordon/py-scaffolding/actions/workflows/release.yaml/badge.svg)](https://github.com/lordgordon/py-scaffolding/actions/workflows/release.yaml)

## Requirements and setup

- [brew](https://brew.sh/).
- Linux/UNIX compatible system with `make` command.
- [Docker](https://www.docker.com/). For macOS users, [colima](https://github.com/abiosoft/colima) is strongly suggested.
- [uv](https://docs.astral.sh/uv/).

Then, to set everything up on macOS:
```shell
brew install uv
make
```

## Release and Changelog

Version bump and changelog update:
```shell
# PATCH
uv run cz bump --increment PATCH -ch --dry-run
# MINOR
uv run cz bump --increment MINOR -ch --dry-run
# MAJOR
uv run cz bump --increment MAJOR -ch --dry-run
```

If OK, run again without `--dry-run`. For full details see
https://commitizen-tools.github.io/commitizen/bump/

## Commands

The main command that run everything (lint, test, build):
```shell
make
```

Then, to execute the main entry point with the local Python environment:
```shell
make run-locally
```

or, to execute the main entry point from Docker:
```shell
make run
```

or, to open a shell in the Docker image:
```shell
make run-shell
```

`make help` to the rescue in case of doubts.

### Run the production image

To run the main entry point with the production image, first build the production image:
```shell
make build
```

Then:
```shell
docker run --platform linux/amd64 --rm -it py-scaffolding:current-local
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
| `make run`         | Execute the main entry point from Docker.                                                                                                            |
| `make run-locally` | Execute the main entry point locally (with uv).                                                                                                  |
| `make run-shell`   | Open a shell in the Docker image.                                                                                                                    |
