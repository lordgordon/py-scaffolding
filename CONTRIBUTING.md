# Contributing to this project

## Pull Request

All development must be done in a short-lived branch in your local clone.

```sh
git checkout -b 00-my-work
```

Before submitting your PR, make sure to have
run all linting and test. To be sure,
just run `make` and check there are no errors and no files left. Commit all new `poetry` updates.

```
git push --set-upstream origin 00-my-work
```

Open the PR following the PR's template guidelines.

### For reviewer

PRs are merged with `squash commit`.
