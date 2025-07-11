{{/*
Expand the name of the chart.
*/}}
{{- define "sessionmanager-chart.name" -}}
{{- default .Chart.Name .Values.deploy.app | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "sessionmanager-chart.fullname" -}}
{{- if .Values.deploy.app }}
{{- .Values.deploy.app | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.deploy.app }}
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
{{- define "sessionmanager-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "sessionmanager-chart.labels" -}}
{{ include "sessionmanager-chart.selectorLabels" . }}
{{- if .Values.deploy.appVersion }}
app.kubernetes.io/version: {{ .Values.deploy.appVersion }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if $.Values.kubeit }}
{{- if $.Values.kubeit.tenantName }}
tenant: {{ $.Values.kubeit.tenantName }}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "sessionmanager-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sessionmanager-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
