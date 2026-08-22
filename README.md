# kubernetes

all configs to deploy mtvl to kubernetes

## Requirements
- external-dns
- cert-manager
- ingress-nginx **or** Traefik (IngressRoute CRDs)

## Steps
> Note that the configs here are only to get the app running on an already existing/bootstrapped
kubernetes cluster.

1. cd `klu`
1. make deploy

To route with Traefik IngressRoutes instead of Kubernetes Ingress, set `ingress.provider: traefik` in `klu/vars.yaml`.
