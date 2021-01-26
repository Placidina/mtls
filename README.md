# Mutual TLS Authentication

POC for Nginx ingress controller mTLS.

## Requirements

- Ansible >= `2.10`
  - Ansible Galaxy Packages:
    - `community.kubernetes`
- Helm >= v3
- Kubectl
- kind
- Make
- Docker

## Usage

If exists kind network IP set in `manifests/metallb-configmap.yml:12`.

```sh
make
```

> If not seted kind network IP, update manifest `manifests/metallb-configmap.yml:12` and apply.

> Discovery kind network IP, run `docker network inspect -f '{{.IPAM.Config}}' kind`

Add nginx ingress ip in you `/etc/hosts`

```sh
# /etc/hosts

172.25.30.1 placidina.int
```

> Discovery ingress IP, run `kubectl get svc -n ingress`

**Makefile:**

| Argument | Description |
|---|---|
| `create` | Create a certificates and cluster |
| `destroy` | Destroy cluster |
| `test` | Test authenticated mTLS request |

## About

- [Kind](https://kind.sigs.k8s.io/)
  - [LoadBalancer](https://kind.sigs.k8s.io/docs/user/loadbalancer/)
- [MetalLB](https://metallb.universe.tf/)
- [Certificates](https://kubernetes.io/pt/docs/concepts/cluster-administration/certificates/)
- [Nginx Ingress Controller mTLS](https://kubernetes.github.io/ingress-nginx/examples/auth/client-certs/)