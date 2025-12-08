# Contributing to PLTF.dev Helm Charts

Thank you for your interest in contributing to the PLTF.dev Helm Charts repository! This document outlines the process and requirements for contributing.

## Prerequisites

Before contributing, ensure you have the following tools installed:

- [Helm](https://helm.sh/docs/intro/install/) (v3.15.3 or later)
- [helm-unittest](https://github.com/helm-unittest/helm-unittest) plugin
- [chart-testing (ct)](https://github.com/helm/chart-testing) for linting and testing

## Pull Request Requirements

### PR Title Format

This repository enforces [Conventional Commits](https://www.conventionalcommits.org/) for PR titles. Your PR title must follow this format:

```text
<type>(<scope>): <description>
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

**Scopes (optional):**

- `deps` - Dependency updates
- `docs` - Documentation changes
- `github` - GitHub-related changes
- `deployment` - Deployment chart changes
- `external-secrets-refresher` - External secrets refresher chart changes
- `external-services` - External services chart changes

**Examples:**

- `feat(deployment): add support for horizontal pod autoscaling`
- `fix: correct template rendering for service annotations`
- `docs: update installation instructions`

### Automated Checks

All PRs must pass the following automated checks:

1. **Chart Linting** - Charts are linted using `ct lint` to ensure they follow best practices
2. **Unit Tests** - If your chart has a `tests/` directory, unit tests will be run using `helm unittest`
3. **Install Tests** - Charts are tested for installability in a Kind cluster
4. **Upgrade Tests** - Charts are tested for upgrade compatibility

## Development Workflow

### 1. Fork and Clone

```bash
git clone https://github.com/<your-username>/helm-charts.git
cd helm-charts
```

### 2. Create a Branch

```bash
git checkout -b feat/my-new-feature
```

### 3. Make Changes

- Charts are located in the `charts/` directory
- Each chart should have its own directory with standard Helm chart structure
- Include unit tests in a `tests/` subdirectory when applicable

### 4. Test Locally

```bash
# Lint your chart
ct lint --charts charts/<your-chart>

# Run unit tests (if applicable)
helm unittest charts/<your-chart>

# Test template rendering
helm template charts/<your-chart>
```

### 5. Submit PR

- Ensure your PR title follows the conventional commits format
- Provide a clear description of changes
- Reference any related issues

## Chart Versioning

When making changes to a chart:

- **Patch version** (0.0.X): Bug fixes, minor changes
- **Minor version** (0.X.0): New features, non-breaking changes
- **Major version** (X.0.0): Breaking changes

Update the `version` field in `Chart.yaml` accordingly.

## Release Process

Charts are automatically released when changes are merged to `main`. The [chart-releaser](https://github.com/helm/chart-releaser) action:

1. Packages changed charts
2. Creates GitHub releases with automatically generated release notes
3. Updates the Helm repository index

## Stale Issues and PRs

To keep the repository clean:

- Issues and PRs inactive for **60 days** will be marked as stale
- Stale items will be **closed after 7 days** of additional inactivity
- Items labeled `on-hold`, `pinned`, or `security` are exempt from this policy

## Questions?

If you have questions or need help, feel free to open an issue for discussion.
