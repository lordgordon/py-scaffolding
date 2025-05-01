# py-scaffolding

My custom Python project scaffolding repository: https://github.com/lordgordon/py-scaffolding.

Docker images published at https://hub.docker.com/repository/docker/lordgordon/py-scaffolding.

:point_right: Note: to release the project as a Python library, you need to run `uv build` and add the proper ci/cd
to publish the library.

---

![pr-validation](https://github.com/lordgordon/py-scaffolding/workflows/pr-validation/badge.svg?branch=main)
[![release](https://github.com/lordgordon/py-scaffolding/actions/workflows/release.yaml/badge.svg)](https://github.com/lordgordon/py-scaffolding/actions/workflows/release.yaml)

## Create a new repository from this template

After creating a new GitHub repository from this template:

1. Create a new branch to scaffold the project.
2. Find and replace all `py-scaffolding` or `py_scaffolding` references with the new repository name.
3. Review and update:
   - `pyproject.toml`. In particular items in the `[project]` section. Update your license.
   - `src/<your_project>/__version__.py`. Align description and license with the project's TOML.
   - `CODEOWNERS`.
   - `CONTRIBUTING.md`.
   - `LICENSE`.
   - `README.md`.
   - `RELEASE.md`.
4. In `pyproject.toml`/`[tool.commitizen]` and `Makefile`/`bump-patch/minor/major`, review the configuration and
   commands for [commitizen](https://commitizen-tools.github.io/commitizen/) to align them with your requirements.
5. Review and modify ci/cd accordingly. You may need to remove unnecessary steps.
6. Run the steps described in the "Requirements and setup" section.

## Requirements and setup

- [brew](https://brew.sh/).
- Linux/UNIX compatible system with `make` command.
- [Docker](https://www.docker.com/). For macOS users, [colima](https://github.com/abiosoft/colima) is strongly suggested.
- [uv](https://docs.astral.sh/uv/).

Then, to set everything up on macOS:

```shell
brew install uv
make install
make
```

## Release and Changelog

Version bump and changelog update:

- `make bump-patch`
- `make bump-minor`
- `make bump-major`

For full details see [commitizen](https://commitizen-tools.github.io/commitizen/bump/).

## Commands

The main command that runs the most common checks (lint, test):

```shell
make dev
```

When ready, just run `make` to validate everything.

Then, to execute the main entry point with the local Python environment:

```shell
make run-locally
```

or, to execute the main entry point from Docker using the production image:

```shell
make run
```

or, to open a shell in the testing Docker image:

```shell
make run-shell-testing
```

To keep the packages updated, run `make upgrade`.

### Makefile commands

```shell
make help
```
