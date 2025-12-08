# Releem Agent Helm Chart

A Helm chart for deploying [Releem Agent](https://releem.com/) on Kubernetes. Releem is a MySQL performance optimization tool that automatically tunes your database configuration.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+

## Installation

```bash
helm repo add pltf https://pltf-dev.github.io/helm-charts
helm repo update
helm install releem-agent pltf/releem-agent -f values.yaml
```

Or install from local chart:

```bash
helm install releem-agent ./charts/releem-agent -f values.yaml
```

## Configuration

### Image Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Image repository | `releem/releem-agent` |
| `image.tag` | Image tag (defaults to chart appVersion) | `""` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `imagePullSecrets` | Image pull secrets | `[]` |

### Databases Configuration

The chart creates one deployment per database entry. Each database can override the default configuration values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `databases` | List of database configurations | `[]` |
| `databases[].name` | **Required.** Unique name for the database (used in deployment name) | - |
| `databases[].debug` | Enable debug mode | Inherits from `config.debug` |
| `databases[].memoryLimit` | Memory limit for the agent | Inherits from `config.memoryLimit` |
| `databases[].releemEnv` | Releem environment | Inherits from `config.releemEnv` |
| `databases[].releemHostname` | Hostname identifier for Releem | Inherits from `config.releemHostname` |
| `databases[].queryOptimization` | Enable query optimization | Inherits from `config.queryOptimization` |
| `databases[].awsRegion` | AWS region (for RDS instances) | Inherits from `config.awsRegion` |
| `databases[].awsRdsParameterGroup` | AWS RDS parameter group name | Inherits from `config.awsRdsParameterGroup` |
| `databases[].instanceType` | Instance type: `local` or `aws/rds` | Inherits from `config.instanceType` |
| `databases[].intervalGenerateConfigSeconds` | Config generation interval in seconds | Inherits from `config.intervalGenerateConfigSeconds` |

### Default Configuration

These values are used as defaults when not specified in the database entry.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `config.debug` | Enable debug mode | `"false"` |
| `config.memoryLimit` | Memory limit (0 = auto-detect) | `"0"` |
| `config.releemEnv` | Releem environment | `"prod"` |
| `config.releemHostname` | Hostname identifier | `"releem"` |
| `config.queryOptimization` | Enable query optimization | `"false"` |
| `config.awsRegion` | AWS region | `"us-east-1"` |
| `config.awsRdsParameterGroup` | AWS RDS parameter group | `""` |
| `config.instanceType` | Instance type: `local` or `aws/rds` | `"local"` |
| `config.intervalGenerateConfigSeconds` | Config generation interval | `"43200"` |

### Secrets Configuration

Sensitive values like API keys and database credentials should be stored in Kubernetes secrets.

#### Using Built-in Secret

| Parameter | Description | Default |
|-----------|-------------|---------|
| `secret.create` | Create a secret with credentials | `false` |
| `secret.data.RELEEM_API_KEY` | Releem API key | `""` |
| `secret.data.DB_PASSWORD` | Database password | `""` |
| `secret.data.DB_HOST` | Database host | `""` |
| `secret.data.DB_PORT` | Database port | `"3306"` |

#### Using External Secrets Operator

| Parameter | Description | Default |
|-----------|-------------|---------|
| `externalSecrets.enabled` | Enable External Secrets integration | `false` |
| `externalSecrets.secretStore.name` | Secret store name | `secrets-store-cluster` |
| `externalSecrets.secretStore.type` | Secret store type | `ClusterSecretStore` |
| `externalSecrets.dataFrom` | Data source configuration | `{}` |

### Pod Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas per deployment | `1` |
| `podAnnotations` | Pod annotations | `{}` |
| `podLabels` | Additional pod labels | `{}` |
| `podSecurityContext` | Pod security context | `{}` |
| `securityContext` | Container security context | `{}` |
| `resources.limits.cpu` | CPU limit | `"1"` |
| `resources.limits.memory` | Memory limit | `1Gi` |
| `resources.requests.cpu` | CPU request | `250m` |
| `resources.requests.memory` | Memory request | `512Mi` |
| `nodeSelector` | Node selector | `{}` |
| `tolerations` | Tolerations | `[]` |
| `affinity` | Affinity rules | `{}` |

### Probes and Lifecycle

| Parameter | Description | Default |
|-----------|-------------|---------|
| `livenessProbe` | Liveness probe configuration | `{}` |
| `readinessProbe` | Readiness probe configuration | `{}` |
| `lifecycle` | Container lifecycle hooks | `{}` |

### Service Account

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.create` | Create a service account | `true` |
| `serviceAccount.automount` | Automount API credentials | `true` |
| `serviceAccount.annotations` | Service account annotations | `{}` |
| `serviceAccount.name` | Service account name | `""` |

### Autoscaling

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable HPA | `false` |
| `autoscaling.minReplicas` | Minimum replicas | `1` |
| `autoscaling.maxReplicas` | Maximum replicas | `100` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization | `80` |

### Volumes

| Parameter | Description | Default |
|-----------|-------------|---------|
| `volumes` | Additional volumes | `[]` |
| `volumeMounts` | Additional volume mounts | `[]` |

## Examples

### Single Database (Local MySQL)

```yaml
databases:
  - name: my-local-db
    releemHostname: "my-mysql-server"

secret:
  create: true
  data:
    RELEEM_API_KEY: "your-api-key"
    DB_HOST: "mysql.default.svc.cluster.local"
    DB_PORT: "3306"
    DB_PASSWORD: "your-db-password"
```

### Multiple Databases

```yaml
config:
  # Default values for all databases
  releemEnv: "prod"
  instanceType: "local"

databases:
  - name: prod-mysql
    releemHostname: "prod-mysql-primary"
    queryOptimization: "true"

  - name: staging-mysql
    releemHostname: "staging-mysql"
    debug: "true"
    releemEnv: "staging"

secret:
  create: true
  data:
    RELEEM_API_KEY: "your-api-key"
    DB_HOST: "mysql.default.svc.cluster.local"
    DB_PASSWORD: "your-db-password"
```

### AWS RDS Database

```yaml
databases:
  - name: rds-production
    releemHostname: "my-rds-instance"
    instanceType: "aws/rds"
    awsRegion: "us-west-2"
    awsRdsParameterGroup: "my-parameter-group"

secret:
  create: true
  data:
    RELEEM_API_KEY: "your-api-key"
    DB_HOST: "my-rds-instance.abc123.us-west-2.rds.amazonaws.com"
    DB_PORT: "3306"
    DB_PASSWORD: "your-db-password"
```

### Using External Secrets Operator

```yaml
databases:
  - name: my-database
    releemHostname: "my-mysql"

externalSecrets:
  enabled: true
  secretStore:
    name: aws-secrets-manager
    type: ClusterSecretStore
  dataFrom:
    - find:
        path: /releem
        name:
          regexp: "RELEEM.*"
      rewrite:
        - regexp:
            source: "/releem/(.*)"
            target: "$1"
```

## Upgrading

```bash
helm upgrade releem-agent pltf/releem-agent -f values.yaml
```

## Uninstalling

```bash
helm uninstall releem-agent
```

## License

This chart is maintained by [pltf.dev](https://pltf.dev).
