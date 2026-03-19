{{/*
Expand the name of the chart.
*/}}
{{- define "galactus.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name. Truncated to 63 chars (K8s name limit).
*/}}
{{- define "galactus.fullname" -}}
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
Chart label value.
*/}}
{{- define "galactus.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "galactus.labels" -}}
helm.sh/chart: {{ include "galactus.chart" . }}
{{ include "galactus.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "galactus.selectorLabels" -}}
app.kubernetes.io/name: {{ include "galactus.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name.
*/}}
{{- define "galactus.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "galactus.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
PostgreSQL host — subchart or external.
*/}}
{{- define "galactus.postgresHost" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%s-postgresql" (include "galactus.fullname" .) }}
{{- else }}
{{- .Values.externalDatabase.host }}
{{- end }}
{{- end }}

{{/*
PostgreSQL port.
*/}}
{{- define "galactus.postgresPort" -}}
{{- if .Values.postgresql.enabled }}
{{- "5432" }}
{{- else }}
{{- .Values.externalDatabase.port | default "5432" }}
{{- end }}
{{- end }}

{{/*
PostgreSQL database name.
*/}}
{{- define "galactus.postgresDB" -}}
{{- if .Values.postgresql.enabled }}
{{- .Values.postgresql.auth.database }}
{{- else }}
{{- .Values.externalDatabase.name }}
{{- end }}
{{- end }}

{{/*
PostgreSQL user.
*/}}
{{- define "galactus.postgresUser" -}}
{{- if .Values.postgresql.enabled }}
{{- .Values.postgresql.auth.username }}
{{- else }}
{{- .Values.externalDatabase.user }}
{{- end }}
{{- end }}

{{/*
PostgreSQL password.
*/}}
{{- define "galactus.postgresPassword" -}}
{{- if .Values.postgresql.enabled }}
{{- .Values.postgresql.auth.password }}
{{- else }}
{{- .Values.externalDatabase.password }}
{{- end }}
{{- end }}

{{/*
Redis URL — subchart or external.
*/}}
{{- define "galactus.redisURL" -}}
{{- if .Values.redis.enabled }}
{{- printf "redis://%s-redis-master:%s/0" (include "galactus.fullname" .) "6379" }}
{{- else }}
{{- printf "redis://%s:%s/0" .Values.externalRedis.host (.Values.externalRedis.port | default "6379") }}
{{- end }}
{{- end }}

{{/*
Redis address (host:port) for KEDA triggers.
*/}}
{{- define "galactus.redisAddress" -}}
{{- if .Values.redis.enabled }}
{{- printf "%s-redis-master:6379" (include "galactus.fullname" .) }}
{{- else }}
{{- printf "%s:%s" .Values.externalRedis.host (.Values.externalRedis.port | default "6379") }}
{{- end }}
{{- end }}

{{/*
Common environment variables from ConfigMap and Secret refs.
Used by all workloads.
*/}}
{{- define "galactus.envFrom" -}}
- configMapRef:
    name: {{ include "galactus.fullname" . }}
- secretRef:
    name: {{ include "galactus.fullname" . }}
{{- end }}

{{/*
GCP credentials volume mount (non-GKE fallback).
*/}}
{{- define "galactus.gcpVolumeMount" -}}
{{- if .Values.gcp.credentialsSecret }}
- name: gcp-credentials
  mountPath: {{ .Values.gcp.credentialsMountPath }}
  readOnly: true
{{- end }}
{{- end }}

{{/*
GCP credentials volume (non-GKE fallback).
*/}}
{{- define "galactus.gcpVolume" -}}
{{- if .Values.gcp.credentialsSecret }}
- name: gcp-credentials
  secret:
    secretName: {{ .Values.gcp.credentialsSecret }}
{{- end }}
{{- end }}
