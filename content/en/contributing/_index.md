---
title: "Contributing"
description: "How to contribute to Rivaas"
weight: 60
sidebar_root_for: self
no_list: true
keywords:
  - contributing
  - development
  - pull request
  - standards
  - guidelines
---

Thank you for your interest in contributing to Rivaas! We welcome contributions from everyone.

## Ways to Contribute

You can help Rivaas in many ways:

- **Report bugs** — Tell us what's broken
- **Suggest features** — Share your ideas
- **Write documentation** — Help others understand Rivaas
- **Fix bugs** — Submit pull requests
- **Add features** — Build new functionality
- **Review code** — Help us maintain quality

## Getting Started

### 1. Find Something to Work On

Good first steps:

- Browse [open issues](https://github.com/rivaas-dev/rivaas/issues)
- Look for issues tagged `good first issue`
- Check the [discussion board](https://github.com/rivaas-dev/rivaas/discussions)
- Propose your own ideas

### 2. Set Up Your Environment

Fork and clone the repository:

```bash
git clone https://github.com/YOUR-USERNAME/rivaas.git
cd rivaas
```

Rivaas uses Nix for development. If you have Nix installed:

```bash
nix develop
```

This gives you all the tools you need.

### 3. Make Your Changes

Create a new branch:

```bash
git checkout -b my-feature
```

Make your changes and test them:

```bash
# Run tests
go test ./...

# Run tests with race detection
go test -race ./...

# Check code style
golangci-lint run
```

### 4. Submit Your Work

Push your changes and create a pull request:

```bash
git push origin my-feature
```

Then open a pull request on GitHub.

## Development Standards

We have clear standards for code quality. Please follow these guides:

### Documentation Standards

Learn how to write good documentation for Go code.

[Documentation Standards →](documentation-standards/)

### Testing Standards

Learn how to test your code properly.

[Testing Standards →](testing-standards/)

## Code Review Process

When you submit a pull request:

1. **Automated checks run** — Tests, linting, and coverage checks
2. **Maintainer reviews** — A maintainer looks at your code
3. **Feedback loop** — You address any comments
4. **Approval** — Maintainer approves when ready
5. **Merge** — Your code becomes part of Rivaas!

## Pull Request Guidelines

### Good pull requests:

- **Focus on one thing** — Don't mix unrelated changes
- **Include tests** — Test your changes
- **Update documentation** — Keep docs current
- **Follow style guides** — Match existing code style
- **Write clear commit messages** — Explain what and why

### Commit messages:

Use clear, descriptive commit messages:

```
Add user authentication middleware

This adds JWT authentication middleware for protecting routes.
It validates tokens and adds user info to the context.

Fixes #123
```

Format:
- First line: Brief summary (under 72 characters)
- Blank line
- Detailed description (if needed)
- Reference issues with `Fixes #123` or `Closes #456`

## Code of Conduct

We want Rivaas to be welcoming to everyone. Please:

- **Be respectful** — Treat others kindly
- **Be constructive** — Give helpful feedback
- **Be patient** — Everyone learns at different speeds
- **Be inclusive** — Welcome diverse perspectives

## Questions?

Not sure about something? Ask!

- **Discussions:** [github.com/rivaas-dev/rivaas/discussions](https://github.com/rivaas-dev/rivaas/discussions)
- **Issues:** [github.com/rivaas-dev/rivaas/issues](https://github.com/rivaas-dev/rivaas/issues)

## License

By contributing to Rivaas, you agree that your contributions will be licensed under the Apache License 2.0.

## Thank You!

Your contributions make Rivaas better for everyone. Thank you for helping!
