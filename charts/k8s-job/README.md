# k8s-job Helm Chart

A generic Helm chart for deploying Kubernetes Jobs with configurable RBAC, service accounts, and ArgoCD integration.

## Key Features

- **Multiple Jobs**: Define multiple jobs in a single release via the `jobs` map
- **Defaults + Overrides**: Global `jobDefaults` with per-job override capability
- **RBAC Support**: Optional Role/ClusterRole and RoleBinding/ClusterRoleBinding per job
- **External Secrets**: Integration with External Secrets Operator using dataFrom with regex
- **ArgoCD Integration**: Pre-configured hooks and sync waves for GitOps workflows
- **AWS IRSA**: Service account annotations for IAM Roles for Service Accounts
- **Flexible Configuration**: Support for env vars, secrets, volumes, resources, and scheduling

## Quick Start

### Minimum Values

```yaml
jobs:
  my-job:
    enabled: true
    command: ["echo"]
    args: ["Hello, World!"]
```

### Deploy a Lambda Function

```yaml
jobs:
  deploy-lambda:
    enabled: true
    image:
      repository: node
      tag: "20-alpine"
    command: ["npm"]
    args: ["run", "deploy:prod"]
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/lambda-deploy
```

### Job with RBAC

```yaml
jobs:
  k8s-task:
    enabled: true
    image:
      repository: alpine/k8s
      tag: "1.34.1"
    command: ["/bin/sh", "-c"]
    args: ["kubectl get configmaps"]
    rbac:
      create: true
      rules:
        - apiGroups: [""]
          resources: ["configmaps"]
          verbs: ["get", "list"]
```

### Job with ClusterRole

```yaml
jobs:
  cluster-task:
    enabled: true
    image:
      repository: alpine/k8s
      tag: "1.34.1"
    command: ["/bin/sh", "-c"]
    args: ["kubectl get nodes"]
    rbac:
      create: true
      clusterScope: true
      rules:
        - apiGroups: [""]
          resources: ["nodes"]
          verbs: ["get", "list"]
```

### Job with External Secrets

```yaml
jobs:
  deploy-lambda:
    enabled: true
    command: ["npm"]
    args: ["run", "deploy:prod"]
    envFrom:
      - secretRef:
          name: lambda-secrets
    externalSecret:
      enabled: true
      name: lambda-secrets
      dataFrom:
        path: /cf2/production/lambda/
        regexp: ".*"
        rewrite:
          source: "/cf2/production/lambda/(.*)"
          target: "$1"
```

## Configuration

### Global Defaults (`jobDefaults`)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Default container image | `node` |
| `image.tag` | Default image tag | `20-alpine` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `ttlSecondsAfterFinished` | Job cleanup time | `600` |
| `backoffLimit` | Job retry limit | `1` |
| `completions` | Number of completions | `1` |
| `parallelism` | Parallel pod count | `1` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `256Mi` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `128Mi` |

### Per-Job Configuration

Each job under `jobs.<name>` can override any default and supports:

| Parameter | Description |
|-----------|-------------|
| `enabled` | Enable/disable the job |
| `image.repository` | Container image |
| `image.tag` | Image tag |
| `command` | Container command (entrypoint) |
| `args` | Container arguments |
| `workingDir` | Working directory |
| `env` | Environment variables list |
| `envFrom` | Environment from secrets/configmaps |
| `resources` | CPU/memory limits and requests |
| `volumes` | Volume definitions |
| `volumeMounts` | Volume mount paths |
| `nodeSelector` | Node selection constraints |
| `tolerations` | Pod tolerations |
| `affinity` | Pod affinity rules |
| `podSecurityContext` | Pod-level security context |
| `securityContext` | Container-level security context |

### Service Account Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.annotations` | SA annotations (e.g., IRSA) | `{}` |

### RBAC Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `rbac.create` | Create RBAC resources | `false` |
| `rbac.clusterScope` | Use ClusterRole instead of Role | `false` |
| `rbac.rules` | RBAC rules list | `[]` |

### ArgoCD Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `argocd.hook` | ArgoCD hook type | `PreSync` |
| `argocd.syncWave` | Sync wave for job | `1` |
| `argocd.hookDeletePolicy` | Hook delete policy | `BeforeHookCreation` |

### External Secrets Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `externalSecret.enabled` | Enable ExternalSecret creation | `false` |
| `externalSecret.name` | Secret name (defaults to job fullname) | `""` |
| `externalSecret.refreshInterval` | How often to sync secrets | `"0"` |
| `externalSecret.refreshPolicy` | When to refresh secrets (OnChange, Always) | `OnChange` |
| `externalSecret.secretStoreRef.name` | SecretStore name | `aws-parameter-store-cluster` |
| `externalSecret.secretStoreRef.kind` | SecretStore kind | `ClusterSecretStore` |
| `externalSecret.creationPolicy` | Secret creation policy | `Owner` |
| `externalSecret.deletionPolicy` | Secret deletion policy | `Retain` |
| `externalSecret.dataFrom.path` | Parameter store path prefix | `""` |
| `externalSecret.dataFrom.regexp` | Regex pattern for matching secrets | `""` |
| `externalSecret.dataFrom.rewrite.source` | Regex source pattern for key rewriting | `""` |
| `externalSecret.dataFrom.rewrite.target` | Replacement pattern for key rewriting | `""` |

## ArgoCD Sync Waves

Resources are created in the following order:

1. **Wave -1**: ExternalSecret (ensures secrets are available before job runs)
2. **Wave 0**: ServiceAccount, Role/ClusterRole, RoleBinding/ClusterRoleBinding
3. **Wave 1**: Job (default, configurable per job)

## Full Example

```yaml
jobDefaults:
  resources:
    limits:
      cpu: "1"
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi

jobs:
  deploy-lambda-prod:
    enabled: true
    image:
      repository: node
      tag: "20-alpine"
    command: ["npm"]
    args: ["run", "deploy:prod"]
    workingDir: /app
    env:
      - name: NODE_ENV
        value: production
      - name: AWS_REGION
        value: us-east-1
    envFrom:
      - secretRef:
          name: lambda-secrets
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/lambda-deploy
    resources:
      limits:
        cpu: "2"
        memory: 1Gi
    argocd:
      hook: PostSync
      syncWave: "2"

  notify-slack:
    enabled: true
    image:
      repository: curlimages/curl
      tag: "8.5.0"
    command: ["/bin/sh", "-c"]
    args:
      - |
        curl -X POST $SLACK_WEBHOOK_URL -d '{"text":"Deployment complete!"}'
    envFrom:
      - secretRef:
          name: slack-webhook
    argocd:
      hook: PostSync
      syncWave: "3"
```

## Installation

```bash
helm install my-jobs charts/k8s-job -f values.yaml
```

## Template Validation

```bash
helm template my-jobs charts/k8s-job -f values.yaml
```
