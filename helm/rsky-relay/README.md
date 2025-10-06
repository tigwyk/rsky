# rsky-relay Helm Chart

This Helm chart deploys rsky-relay, an AT Protocol relay server implementation written in Rust, on a Kubernetes cluster.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure (if persistence is enabled)

## Installing the Chart

To install the chart with the release name `my-rsky-relay`:

```bash
helm install my-rsky-relay ./helm/rsky-relay
```

The command deploys rsky-relay on the Kubernetes cluster with the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `my-rsky-relay` deployment:

```bash
helm delete my-rsky-relay
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the rsky-relay chart and their default values.

### Global Parameters

| Name                      | Description                                     | Value |
| ------------------------- | ----------------------------------------------- | ----- |
| `global.imageRegistry`    | Global Docker image registry                    | `""`  |

### Common Parameters

| Name               | Description                                        | Value |
| ------------------ | -------------------------------------------------- | ----- |
| `replicaCount`     | Number of rsky-relay replicas to deploy           | `1`   |

### Image Parameters

| Name                | Description                                          | Value                  |
| ------------------- | ---------------------------------------------------- | ---------------------- |
| `image.registry`    | rsky-relay image registry                            | `docker.io`            |
| `image.repository`  | rsky-relay image repository                          | `blacksky/rsky-relay`  |
| `image.tag`         | rsky-relay image tag                                 | `"latest"`             |
| `image.digest`      | rsky-relay image digest (overrides tag)             | `""`                   |
| `image.pullPolicy`  | rsky-relay image pull policy                         | `IfNotPresent`         |
| `image.pullSecrets` | rsky-relay image pull secrets                        | `[]`                   |

### rsky-relay Configuration

| Name                     | Description                                    | Value   |
| ------------------------ | ---------------------------------------------- | ------- |
| `config.mode`            | Relay mode: "relay" or "labeler"              | `relay` |
| `config.noplcexport`     | Disable PLC export functionality              | `false` |
| `config.logLevel`        | Log level (trace, debug, info, warn, error)   | `info`  |

### SSL Configuration

| Name                    | Description                                  | Value       |
| ----------------------- | -------------------------------------------- | ----------- |
| `ssl.enabled`           | Enable SSL/TLS support                       | `false`     |
| `ssl.existingSecret`    | Existing secret containing SSL certificates  | `""`        |
| `ssl.certKey`           | Key in secret containing certificate file    | `"tls.crt"` |
| `ssl.keyKey`            | Key in secret containing private key file    | `"tls.key"` |
| `ssl.cert`              | Certificate data (base64 encoded)            | `""`        |
| `ssl.key`               | Private key data (base64 encoded)            | `""`        |

### Service Parameters

| Name                                 | Description                               | Value        |
| ------------------------------------ | ----------------------------------------- | ------------ |
| `service.type`                       | rsky-relay service type                   | `ClusterIP`  |
| `service.ports.http`                 | rsky-relay service HTTP port              | `9000`       |
| `service.ports.https`                | rsky-relay service HTTPS port             | `9443`       |
| `service.annotations`                | Additional service annotations            | `{}`         |
| `service.loadBalancerIP`             | LoadBalancer IP (if type is LoadBalancer)| `""`         |
| `service.loadBalancerSourceRanges`   | LoadBalancer source ranges                | `[]`         |

### Ingress Parameters

| Name                       | Description                          | Value                       |
| -------------------------- | ------------------------------------ | --------------------------- |
| `ingress.enabled`          | Enable ingress record generation     | `false`                     |
| `ingress.hostname`         | Default host for ingress record      | `rsky-relay.local`          |
| `ingress.annotations`      | Additional ingress annotations       | `{}`                        |
| `ingress.tls`              | Enable TLS configuration             | `false`                     |
| `ingress.ingressClassName` | IngressClass name                    | `""`                        |

### Persistence Parameters

| Name                          | Description                           | Value           |
| ----------------------------- | ------------------------------------- | --------------- |
| `persistence.enabled`         | Enable persistence using PVC          | `true`          |
| `persistence.mountPath`       | Path to mount the volume              | `/data`         |
| `persistence.storageClass`    | Storage class of backing PVC          | `""`            |
| `persistence.size`            | Size of data volume                   | `100Gi`         |
| `persistence.accessModes`     | PVC access modes                      | `["ReadWriteOnce"]` |
| `persistence.existingClaim`   | Name of existing PVC                  | `""`            |

### Security Context Parameters

| Name                                            | Description                                    | Value           |
| ----------------------------------------------- | ---------------------------------------------- | --------------- |
| `podSecurityContext.enabled`                    | Enabled pod security context                   | `true`          |
| `podSecurityContext.fsGroup`                    | Set pod security context fsGroup              | `1001`          |
| `containerSecurityContext.enabled`             | Enabled container security context             | `true`          |
| `containerSecurityContext.runAsUser`           | Set container security context runAsUser       | `1001`          |
| `containerSecurityContext.runAsNonRoot`        | Set container security context runAsNonRoot    | `true`          |
| `containerSecurityContext.readOnlyRootFilesystem` | Set container readOnlyRootFilesystem        | `true`          |

### Resource Parameters

| Name                     | Description                           | Value      |
| ------------------------ | ------------------------------------- | ---------- |
| `resources.limits`       | Resource limits for containers        | `{memory: 2Gi, cpu: 1000m}` |
| `resources.requests`     | Resource requests for containers      | `{memory: 1Gi, cpu: 500m}`  |

### Autoscaling Parameters

| Name                            | Description                              | Value   |
| ------------------------------- | ---------------------------------------- | ------- |
| `autoscaling.enabled`           | Enable Horizontal POD autoscaling        | `false` |
| `autoscaling.minReplicas`       | Minimum number of replicas               | `1`     |
| `autoscaling.maxReplicas`       | Maximum number of replicas               | `10`    |
| `autoscaling.targetCPU`         | Target CPU utilization percentage        | `50`    |
| `autoscaling.targetMemory`      | Target Memory utilization percentage     | `50`    |

### RBAC Parameters

| Name                        | Description                                | Value  |
| --------------------------- | ------------------------------------------ | ------ |
| `serviceAccount.create`     | Specifies whether ServiceAccount should be created | `true` |
| `serviceAccount.name`       | ServiceAccount name                        | `""`   |
| `rbac.create`               | Specifies whether RBAC should be created  | `true` |

### Network Policy Parameters

| Name                           | Description                              | Value   |
| ------------------------------ | ---------------------------------------- | ------- |
| `networkPolicy.enabled`        | Enable NetworkPolicy creation            | `false` |
| `networkPolicy.allowExternal`  | Allow external connections               | `true`  |

### Monitoring Parameters

| Name                                      | Description                              | Value   |
| ----------------------------------------- | ---------------------------------------- | ------- |
| `metrics.enabled`                         | Enable metrics export                    | `false` |
| `metrics.serviceMonitor.enabled`          | Enable ServiceMonitor creation          | `false` |

## Examples

### Basic Installation

```bash
helm install my-rsky-relay ./helm/rsky-relay
```

### Installation with SSL/TLS

```bash
helm install my-rsky-relay ./helm/rsky-relay \
  --set ssl.enabled=true \
  --set ssl.cert="$(cat cert.pem | base64 -w 0)" \
  --set ssl.key="$(cat key.pem | base64 -w 0)"
```

### Installation in Labeler Mode

```bash
helm install my-rsky-labeler ./helm/rsky-relay \
  --set config.mode=labeler \
  --set replicaCount=2
```

### Installation with Ingress

```bash
helm install my-rsky-relay ./helm/rsky-relay \
  --set ingress.enabled=true \
  --set ingress.hostname=relay.example.com \
  --set ingress.tls=true
```

### Installation with Monitoring

```bash
helm install my-rsky-relay ./helm/rsky-relay \
  --set metrics.enabled=true \
  --set metrics.serviceMonitor.enabled=true
```

## AT Protocol Endpoints

Once deployed, rsky-relay exposes several AT Protocol endpoints:

- `/xrpc/com.atproto.sync.subscribeRepos` - WebSocket endpoint for repository subscriptions
- `/xrpc/com.atproto.sync.listHosts` - Lists available relay hosts
- `/xrpc/com.atproto.sync.getBlob` - Retrieves blobs by CID
- `/xrpc/com.atproto.sync.getRepo` - Retrieves repository data

## Troubleshooting

### Pod not starting

Check the logs:
```bash
kubectl logs -l app.kubernetes.io/name=rsky-relay
```

### SSL Certificate Issues

Ensure certificates are properly base64 encoded:
```bash
cat your-cert.pem | base64 -w 0
cat your-key.pem | base64 -w 0
```

### Network Connectivity Issues

If running in labeler mode, ensure port 9001 is accessible. For relay mode, ensure port 9000 is accessible.

### Persistence Issues

Check PVC status:
```bash
kubectl get pvc
```

Ensure your cluster has a default storage class or specify one in `persistence.storageClass`.

## Contributing

Please refer to the main rsky project for contribution guidelines: https://github.com/blacksky-algorithms/rsky

## License

Apache License 2.0. See the main rsky project for details.