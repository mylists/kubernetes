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

To issue a TLS cert with cert-manager, set `certificate.enabled: true` and `certificate.issuerRef.name` in helm values. `dnsNames` default to `ingress.hosts`, and the issued secret is attached to Ingress or IngressRoute unless those already set a `secretName`.
