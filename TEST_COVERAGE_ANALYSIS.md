# Test Coverage Analysis

## Current State

| Chart | Templates | Test Files | Test Cases | Coverage |
|-------|-----------|------------|------------|----------|
| k8s-job | 6 | 4 | 70 | High |
| external-services | 2 | 1 | 4 | Moderate |
| deployment | 2 | 1 | 3 | Low |
| external-secrets-refresher | 5 | 0 | 0 | None |
| releem-agent | 6 | 0 | 0 | None |

**Total: 77 test cases across 6 test files, covering 3 of 5 charts.**

---

## Gap Analysis

### Priority 1: Charts With Zero Tests

#### 1. `releem-agent` (6 templates, 0 tests) — HIGH PRIORITY

This is the most complex untested chart. It has multiple conditional paths and a range-based multi-database deployment pattern. Recommended tests:

- **deployment.yaml**
  - Renders one Deployment per database entry (range iteration)
  - Fails when `databases[].name` is missing (`required` validation)
  - Sets per-database env vars with fallback to global `config` values
  - Per-database override of config values (e.g., `db.debug` overrides `config.debug`)
  - Omits `replicas` when `autoscaling.enabled` is true
  - Includes `envFrom` only when `secret.create` or `externalSecrets.enabled` is true
  - Sets correct image from `image.repository` and `image.tag`
  - Adds `app.kubernetes.io/database` label to deployment, selector, and pod
  - Truncates name to 63 characters for long names

- **hpa.yaml**
  - Does not render when `autoscaling.enabled` is false
  - Renders HPA with correct min/max replicas when enabled
  - Includes CPU metric when `targetCPUUtilizationPercentage` is set
  - Includes memory metric when `targetMemoryUtilizationPercentage` is set
  - Omits memory metric when `targetMemoryUtilizationPercentage` is not set

- **external-secret.yaml**
  - Does not render when `externalSecrets.enabled` is false
  - Renders ExternalSecret with correct secretStoreRef when enabled
  - Sets target secret name to `<fullname>-es`
  - Includes ArgoCD sync-wave annotation

- **secret.yaml**
  - Does not render when `secret.create` is false
  - Renders Secret with `stringData` from `secret.data` when enabled
  - Sets secret name to `<fullname>-secret`

- **serviceaccount.yaml**
  - Does not render when `serviceAccount.create` is false
  - Renders with correct name and labels when enabled
  - Includes annotations when `serviceAccount.annotations` is set
  - Sets `automountServiceAccountToken` from `serviceAccount.automount`

#### 2. `external-secrets-refresher` (5 templates, 0 tests) — HIGH PRIORITY

All 5 templates are completely untested. Recommended tests:

- **job.yaml**
  - Renders a Job with correct name and labels
  - Sets ArgoCD annotations (hook, sync-wave, hook-delete-policy, sync-options)
  - Configures `ttlSecondsAfterFinished`, `backoffLimit`, `completions`, `parallelism` from values
  - Uses correct image from values
  - Uses the release namespace in the kubectl commands
  - Sets resource limits/requests

- **role.yaml**
  - Renders a Role with correct RBAC rules for ExternalSecret resources
  - Includes ArgoCD annotations

- **role-binding.yaml**
  - Renders a RoleBinding referencing the correct Role and ServiceAccount
  - Includes ArgoCD annotations

- **serviceaccount.yaml**
  - Renders a ServiceAccount with correct name, labels, and ArgoCD annotations

---

### Priority 2: Charts With Inadequate Coverage

#### 3. `deployment` (2 templates, 3 tests) — MEDIUM PRIORITY

The existing 3 tests only cover replicas, image, and command/args. The template has ~20 conditional blocks that are untested:

- **Missing test scenarios:**
  - `env` and `envFrom` rendering
  - `ports` configuration
  - `resources` setting
  - `volumeMounts` and `volumes`
  - `nodeSelector`, `tolerations`, `affinity`
  - `podAnnotations`
  - `podSecurityContext` and `securityContext`
  - `strategy` (e.g., RollingUpdate)
  - `imagePullSecrets`
  - `serviceAccountName` (custom name vs default)
  - `terminationGracePeriodSeconds`
  - `livenessProbe` and `readinessProbe`
  - `nameOverride` and `fullnameOverride` (from _helpers.tpl)
  - Labels are correctly propagated (selector, pod, metadata)

#### 4. `external-services` (2 templates, 4 tests) — LOW PRIORITY

Coverage is reasonable for the chart's simplicity. Minor additions:

- **Missing test scenarios:**
  - Validates the `type: ExternalName` and `externalName` field are correctly set
  - Empty `services` list renders no documents
  - Service port is omitted (ExternalName services typically have no port)

---

### Priority 3: Cross-Cutting Concerns

These apply across multiple charts and are not currently tested anywhere:

#### 5. `_helpers.tpl` testing

No chart tests the helper functions directly (label output, name generation, truncation). While these are indirectly tested through template tests, dedicated tests would catch regressions in:
- `fullname` truncation at 63 characters
- `nameOverride` / `fullnameOverride` behavior
- Label content (`app.kubernetes.io/name`, `app.kubernetes.io/instance`, `helm.sh/chart`, etc.)
- `serviceAccountName` logic (create vs use existing name)

#### 6. Negative / edge-case testing

Most tests only verify the happy path. Missing edge cases:
- Empty values (e.g., empty `env: []`, empty `databases: []`)
- Very long release names (63-char truncation)
- Special characters in values
- Boolean-like string values (e.g., `"true"` vs `true`)

#### 7. Values schema validation

No chart has a `values.schema.json` file. Adding JSON Schema validation would:
- Catch invalid values before template rendering
- Document required vs optional fields
- Enforce type constraints (e.g., `replicaCount` must be integer)
- The `k8s-job` and `releem-agent` charts would benefit most from this

---

## Recommended Action Plan

| Priority | Action | Effort | Impact |
|----------|--------|--------|--------|
| P1 | Add tests for `releem-agent` (all 5 templates) | Medium | High — most complex untested chart |
| P1 | Add tests for `external-secrets-refresher` (all 4 templates) | Low | High — chart is entirely untested |
| P2 | Expand `deployment` tests (env, probes, volumes, security, labels) | Low | Medium — many conditional paths untested |
| P2 | Add edge-case tests to `external-services` | Low | Low |
| P3 | Add `_helpers.tpl` name/label tests across charts | Low | Medium — prevents subtle regressions |
| P3 | Add `values.schema.json` for complex charts | Medium | Medium — catches misconfiguration early |
