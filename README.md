# py-scaffolding
My custom Python project scaffolding repository.
https://github.com/lordgordon/py-scaffolding

## Requirements

- Python 3.9 with [Poetry](https://python-poetry.org) installed globally.
  - `pip3` must be available.
- Linux/UNIX compatible system with `make` command.

On MacOS:
```sh
brew install python@3.9
pip install poetry
```

## Configure VS Code
Run the following commands:
```sh
mkdir .vscode;touch .vscode/settings.json
```

Then put the following JSON in `.vscode/settings.json` and replace the 
`python.pythonPath` value with the output of `poetry env info -p`.

```json
{
    "python.pythonPath": "/path/to/poetry/env",
    "python.poetryPath": "poetry",
    "python.linting.pylintEnabled": true,
    "python.linting.enabled": true
}
```

## Commands

The main command that run everything (except a full clean):
```sh
make
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
| `make lint` | Autolint and code linting. |
| `make test` | Run all the tests with code coverage. |
| `make doc` | Compile and update the internal documentation. |
| `make clean` | Force a clean environment: remove all temporary files and caches. Start from a new environment. |
