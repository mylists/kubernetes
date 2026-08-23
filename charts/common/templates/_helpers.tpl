{{/*
Expand the name of the chart.
*/}}
{{- define "common.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "common.labels" -}}
helm.sh/chart: {{ include "common.chart" . }}
{{ include "common.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "common.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "common.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
True when HTTP should be redirected to HTTPS for the active provider.
Honors ingress.redirectToHTTPS plus the provider-specific flags.
*/}}
{{- define "common.redirectToHTTPS" -}}
{{- if or .Values.ingress.redirectToHTTPS .Values.traefik.redirectToHTTPS .Values.gateway.redirectToHTTPS }}
true
{{- end }}
{{- end }}

{{/*
True when standard Kubernetes Ingress should be rendered.
*/}}
{{- define "common.ingress.enabled" -}}
{{- $provider := .Values.ingress.provider | default "nginx" }}
{{- if and .Values.ingress.enabled (ne $provider "traefik") (ne $provider "gateway") }}
true
{{- end }}
{{- end }}

{{/*
True when Traefik IngressRoute should be rendered.
*/}}
{{- define "common.traefik.enabled" -}}
{{- if and .Values.ingress.enabled (eq (.Values.ingress.provider | default "nginx") "traefik") }}
true
{{- end }}
{{- end }}

{{/*
True when Gateway API HTTPRoute should be rendered.
*/}}
{{- define "common.gateway.enabled" -}}
{{- if and .Values.ingress.enabled (eq (.Values.ingress.provider | default "nginx") "gateway") }}
true
{{- end }}
{{- end }}

{{/*
Gateway / HTTPRoute apiVersion.
*/}}
{{- define "common.gateway.apiVersion" -}}
{{- default "gateway.networking.k8s.io/v1" .Values.gateway.apiVersion }}
{{- end }}

{{/*
Created Gateway name.
*/}}
{{- define "common.gateway.name" -}}
{{- default (include "common.fullname" .) .Values.gateway.name }}
{{- end }}

{{/*
Map Ingress pathType to Gateway API HTTPPathMatch type.
*/}}
{{- define "common.gateway.pathType" -}}
{{- $t := default "Prefix" . -}}
{{- if or (eq $t "Prefix") (eq $t "ImplementationSpecific") }}
PathPrefix
{{- else if eq $t "Exact" }}
Exact
{{- else }}
{{ $t }}
{{- end }}
{{- end }}

{{/*
Sanitize a hostname for use in a resource name.
*/}}
{{- define "common.gateway.hostName" -}}
{{- . | replace "." "-" | replace "*" "wildcard" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
HTTPRoute parentRefs. Uses gateway.parentRefs, else the Gateway created by this chart.
*/}}
{{- define "common.gateway.parentRefs" -}}
{{- if .Values.gateway.parentRefs }}
{{- toYaml .Values.gateway.parentRefs }}
{{- else if .Values.gateway.create }}
- name: {{ include "common.gateway.name" . }}
  {{- if include "common.tls.secretName" . | trim }}
  sectionName: https
  {{- else }}
  sectionName: http
  {{- end }}
{{- end }}
{{- end }}

{{/*
HTTP listener parentRefs for HTTPS redirects.
*/}}
{{- define "common.gateway.httpParentRefs" -}}
{{- if .Values.gateway.httpParentRefs }}
{{- toYaml .Values.gateway.httpParentRefs }}
{{- else if .Values.gateway.create }}
- name: {{ include "common.gateway.name" . }}
  sectionName: http
{{- else }}
{{- range .Values.gateway.parentRefs }}
- name: {{ .name }}
  {{- with .namespace }}
  namespace: {{ . }}
  {{- end }}
  {{- with .group }}
  group: {{ . }}
  {{- end }}
  {{- with .kind }}
  kind: {{ . }}
  {{- end }}
  sectionName: http
  {{- with .port }}
  port: {{ . }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
True when a cert-manager Certificate should be rendered.
*/}}
{{- define "common.certificate.enabled" -}}
{{- if .Values.certificate.enabled }}
true
{{- end }}
{{- end }}

{{/*
Certificate resource name.
*/}}
{{- define "common.certificate.name" -}}
{{- default (include "common.fullname" .) .Values.certificate.name }}
{{- end }}

{{/*
TLS secret name issued by the Certificate.
*/}}
{{- define "common.certificate.secretName" -}}
{{- default (printf "%s-tls" (include "common.fullname" .)) .Values.certificate.secretName }}
{{- end }}

{{/*
DNS names for the Certificate. Uses certificate.dnsNames, else ingress.hosts.
*/}}
{{- define "common.certificate.dnsNames" -}}
{{- $names := .Values.certificate.dnsNames | default list -}}
{{- if not $names }}
{{- range .Values.ingress.hosts }}
{{- $names = append $names .host }}
{{- end }}
{{- end }}
{{- range $names }}
- {{ . | quote }}
{{- end }}
{{- end }}

{{/*
Ingress TLS list. Uses ingress.tls, else the cert-manager secret covering certificate DNS names.
*/}}
{{- define "common.ingress.tls" -}}
{{- if .Values.ingress.tls }}
{{- toYaml .Values.ingress.tls }}
{{- else if .Values.certificate.enabled }}
- hosts:
    {{- include "common.certificate.dnsNames" . | nindent 4 }}
  secretName: {{ include "common.certificate.secretName" . }}
{{- end }}
{{- end }}

{{/*
Primary TLS secret: gateway/traefik secretName, else ingress.tls, else the Certificate secret.
*/}}
{{- define "common.tls.secretName" -}}
{{- if and .Values.gateway .Values.gateway.tls .Values.gateway.tls.secretName }}
{{- .Values.gateway.tls.secretName }}
{{- else if and .Values.traefik .Values.traefik.tls .Values.traefik.tls.secretName }}
{{- .Values.traefik.tls.secretName }}
{{- else if .Values.ingress.tls }}
{{- (index .Values.ingress.tls 0).secretName }}
{{- else if .Values.certificate.enabled }}
{{- include "common.certificate.secretName" . }}
{{- end }}
{{- end }}

{{/*
Build a Traefik router match from host + path + pathType.
*/}}
{{- define "common.traefikMatch" -}}
{{- $host := .host -}}
{{- $path := default "/" .path -}}
{{- $pathType := default "Prefix" .pathType -}}
{{- if or (eq $path "/") (eq $path "") }}
Host(`{{ $host }}`)
{{- else if eq $pathType "Exact" }}
Host(`{{ $host }}`) && Path(`{{ $path }}`)
{{- else }}
Host(`{{ $host }}`) && PathPrefix(`{{ $path }}`)
{{- end }}
{{- end }}
