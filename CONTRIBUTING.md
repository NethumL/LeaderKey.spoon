# Contributing to LeaderKey.spoon

## <a name="commit"></a> Commit Message Format

This specification is inspired by [Angular's commit message format](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#-commit-message-format)

Each commit message consists of a **header**, a **body**, and a **footer**.

```
<header>
<BLANK_LINE>
<body>
<BLANK_LINE>
<footer>
```

The `header` is mandatory and must conform to the [Commit Message Header](#commit-header) format.

The `body` and `footer` are optional, but if present, should conform to the [Commit Message Body](#commit-body) and [Commit Message Footer](#commit-footer) formats respectively.

### <a name="commit-header"></a> Commit Message Header

```
<type>(<scope>): <short summary>
  │       │             │
  │       │             └─⫸ Summary in present tense. Not capitalised. No period at the end.
  │       └─⫸ Commit Scope: gen|helper|re
  │
  └─⫸ Commit Type: build|ci|docs|feat|fix|perf|refactor|test|revert
```

The `<type>` and `<summary>` fields are mandatory, and the `(<scope>)` field is optional.

#### Type

Must be one of the following:

- **build**: Changes that affect the build system or external dependencies
- **ci**: Changes to CI configuration files and scripts
- **docs**: Documentation only changes
- **feat**: New feature
- **fix**: Bug fix
- **perf**: Code change that improves performance
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **test**: Changes that affect tests
- **revert**: Reverts a commit

#### Scope

Usually one of the following:

- **gen**: General
- **helper**: Helper
- **re**: Recursive binding

#### Summary

Use the summary field to provide a succinct description of the change:

- use the imperative, present tense: "change", not "changed" or "changes"
- don't capitalise the first letter
- no period at the end

### <a name="commit-body"></a> Commit Message Body

Just as in the summary, use the imperative, present tense

Explain the motivation for the change in the commit message body. This commit message should explain the reason for the change.
You can include a comparison of the previous behaviour with the new behaviour in order to illustrate the impact of the change.

### <a name="commit-footer"></a> Commit Message Footer

The footer is the place to reference GitHub issues and other PRs that this commit is related to.

For example:

```
Refer <issue>
```

### Revert commits

If a commit reverts a previous commit, it should begin with `revert: `, followed by the header of the reverted commit.

The content of the commit message body should contain:

- information about the SHA of the commit being reverted in the following format: `This reverts commit <SHA>`
- a clear description of the reason for reverting the commit message
