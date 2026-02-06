{{/*
Expand the name of the chart.
*/}}
{{- define "dog.name" -}}
{{- default .Chart.Name .Values.global.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "dog.fullname" -}}
{{- if .Values.global.fullnameOverride }}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.global.nameOverride }}
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
{{- define "dog.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "dog.labels" -}}
helm.sh/chart: {{ include "dog.chart" . }}
{{ include "dog.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "dog.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dog.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* ==========================================================================
   Doris Connection Helpers
   ========================================================================== */}}

{{/*
Get Doris FE host (MySQL protocol)
Doris Operator creates Service with name: <cluster-name>-fe-service
*/}}
{{- define "dog.doris.host" -}}
{{- if eq .Values.doris.mode "external" -}}
{{ required "doris.external.host is required when doris.mode is external" .Values.doris.external.host }}
{{- else -}}
{{ include "dog.doris.clusterName" . }}-fe-service
{{- end -}}
{{- end }}

{{/*
Get Doris FE MySQL port
*/}}
{{- define "dog.doris.port" -}}
{{- if eq .Values.doris.mode "external" -}}
{{ .Values.doris.external.port | default 9030 }}
{{- else -}}
9030
{{- end -}}
{{- end }}

{{/*
Get Doris FE HTTP port (for Web UI and Stream Load routing)
K8s deployed Doris can write data directly through FE HTTP port 8030
*/}}
{{- define "dog.doris.feHttpPort" -}}
{{- if eq .Values.doris.mode "external" -}}
{{ .Values.doris.external.feHttpPort | default 8030 }}
{{- else -}}
8030
{{- end -}}
{{- end }}

{{/*
Get Doris BE HTTP port (for direct Stream Load to BE)
Used in advanced scenarios where direct BE access is needed
*/}}
{{- define "dog.doris.beHttpPort" -}}
{{- if eq .Values.doris.mode "external" -}}
{{ .Values.doris.external.beHttpPort | default 8040 }}
{{- else -}}
8040
{{- end -}}
{{- end }}

{{/*
Get Doris FE HTTP endpoint (for OTel collector Stream Load)
K8s deployed Doris: use FE HTTP port 8030 directly (FE will route to BE)
*/}}
{{- define "dog.doris.feHttpEndpoint" -}}
{{- if eq .Values.doris.mode "external" -}}
http://{{ include "dog.doris.host" . }}:{{ include "dog.doris.feHttpPort" . }}
{{- else -}}
http://{{ include "dog.doris.clusterName" . }}-fe-service:8030
{{- end -}}
{{- end }}

{{/*
Get Doris BE HTTP endpoint (for direct Stream Load to BE)
*/}}
{{- define "dog.doris.beHttpEndpoint" -}}
{{- if eq .Values.doris.mode "external" -}}
http://{{ include "dog.doris.host" . }}:{{ include "dog.doris.beHttpPort" . }}
{{- else -}}
http://{{ include "dog.doris.clusterName" . }}-be-service:8040
{{- end -}}
{{- end }}

{{/*
Get Doris MySQL endpoint (host:port)
*/}}
{{- define "dog.doris.mysqlEndpoint" -}}
{{ include "dog.doris.host" . }}:{{ include "dog.doris.port" . }}
{{- end }}

{{/*
Get Doris username
*/}}
{{- define "dog.doris.user" -}}
{{- if eq .Values.doris.mode "external" -}}
{{ .Values.doris.external.user | default "root" }}
{{- else -}}
root
{{- end -}}
{{- end }}

{{/*
Get Doris password
Note: Returns empty string for internal mode or when using existingSecret
*/}}
{{- define "dog.doris.password" -}}
{{- if eq .Values.doris.mode "external" -}}
{{- if not .Values.doris.external.existingSecret -}}
{{ .Values.doris.external.password | default "" }}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Get Doris database name
*/}}
{{- define "dog.doris.database" -}}
{{ .Values.doris.database | default "otel" }}
{{- end }}

{{/*
Check if using external secret for Doris credentials
*/}}
{{- define "dog.doris.useExistingSecret" -}}
{{- if and (eq .Values.doris.mode "external") .Values.doris.external.existingSecret -}}
true
{{- else -}}
false
{{- end -}}
{{- end }}

{{/* ==========================================================================
   Component Name Helpers
   ========================================================================== */}}

{{/*
OTel Collector full name
*/}}
{{- define "dog.otel.fullname" -}}
{{ include "dog.fullname" . }}-otel-collector
{{- end }}

{{/*
Grafana full name
*/}}
{{- define "dog.grafana.fullname" -}}
{{ include "dog.fullname" . }}-grafana
{{- end }}

{{/*
Doris cluster full name
*/}}
{{- define "dog.doris.clusterName" -}}
{{ include "dog.fullname" . }}-doris
{{- end }}
