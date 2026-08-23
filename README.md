# kubernetes

all configs to deploy mtvl to kubernetes

## Requirements
- external-dns
- cert-manager
- ingress-nginx **or** Traefik (IngressRoute CRDs) **or** Gateway API

## Steps
> Note that the configs here are only to get the app running on an already existing/bootstrapped
kubernetes cluster.

1. cd `klu`
1. make deploy

To route with Traefik IngressRoutes instead of Kubernetes Ingress, set `ingress.provider: traefik` in `klu/vars.yaml`.

To route with Kubernetes Gateway API HTTPRoutes, set `ingress.provider: gateway` in `klu/vars.yaml` and set `gateway.parentRefs` to your Gateway (name, optional namespace / sectionName). To have the chart create a Gateway, set `gateway.create: true` and `gateway.gatewayClassName`. HTTPRoutes are built from `ingress.hosts`.

Set `ingress.redirectToHTTPS: true` to send all HTTP traffic to HTTPS. That adds nginx ssl-redirect annotations, a Traefik redirect IngressRoute, or Gateway API redirect HTTPRoutes, depending on `ingress.provider`. Provider-specific `traefik.redirectToHTTPS` and `gateway.redirectToHTTPS` still work.

To issue a TLS cert with cert-manager, set `certificate.enabled: true` and `certificate.issuerRef.name` in helm values. `dnsNames` default to `ingress.hosts`, and the issued secret is attached to Ingress, IngressRoute, or Gateway unless those already set a `secretName`.
