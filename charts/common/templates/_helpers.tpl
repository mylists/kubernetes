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
True when standard Kubernetes Ingress should be rendered.
*/}}
{{- define "common.ingress.enabled" -}}
{{- if and .Values.ingress.enabled (ne (.Values.ingress.provider | default "nginx") "traefik") }}
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
