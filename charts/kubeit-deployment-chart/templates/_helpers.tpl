{{/*
Expand the name of the chart.
*/}}
{{- define "services-chart.name" -}}
{{- default .Chart.Name .Values.app | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "services-chart.fullname" -}}
{{- if .Values.app }}
{{- .Values.app | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.app }}
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
{{- define "services-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "services-chart.labels" -}}
{{ include "services-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
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
{{- define "services-chart.selectorLabels" -}}
app: {{ include "services-chart.name" . }}
app.kubernetes.io/name: {{ include "services-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the serviceaccount to use
*/}}
{{- define "services-chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "services-chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "services-chart.virtualserviceContent" -}}
{{- $prefixes := default (list $.Values.app) $.Values.defaultRouting.urlPrefixes }}
{{- $regexes := $.Values.defaultRouting.urlRegexes }}
http:
{{- if $.Values.defaultRouting.urlExactMatches }}
  - match:
  {{- range $.Values.defaultRouting.urlExactMatches }}
  {{- if hasPrefix "/" . }}
    {{ fail "url matches must not include leading slash"}}
  {{- end}}
  {{- $slashMatch := printf "/%s" . }}
    - uri:
        exact: {{ $slashMatch }}
    - uri:
        prefix: {{ $slashMatch }}/
  {{- end }}
  # routes to service
    route:
    - destination:
        host: {{ include "platform-service.fullQualifiedServiceName" $ | quote }}
{{- if $.Values.defaultRouting.corsPolicy }}
  corsPolicy:
{{ $.Values.defaultRouting.corsPolicy | toYaml | trim | indent 4 }}
{{- end }}
{{- end }}

{{- if $.Values.defaultRouting.redirectOnNoTrailingSlash }}
  # redirect on prefixes without trailing slashes
  {{- range $prefixes }}
  {{- $slashPrefix := printf "/%s" . }}
  - match:
    - uri:
        exact: {{ $slashPrefix }}
    redirect:
      uri: {{ $slashPrefix }}/
  {{- end}}
{{- end}}
  # routes to service
  - route:
    - destination:
        host: {{ include "platform-service.fullQualifiedServiceName" $ | quote }}
{{- if $.Values.defaultRouting.corsPolicy }}
    corsPolicy:
{{ $.Values.defaultRouting.corsPolicy | toYaml | trim | indent 4 }}
{{- end -}}

  {{- if not $.Values.defaultRouting.catchAll }}
    match:
    {{- range $prefixes }}
    {{- if hasPrefix "/" . }}
      {{ fail "url prefixes must not include leading slash"}}
    {{- end}}
    {{- $slashPrefix := printf "/%s" . }}
    - uri:
        prefix: {{ $slashPrefix }}/
    {{- end }}
    {{- range $regexes }}
    - uri:
        regex: {{ . }}
    {{- end }}
  {{- end }}
{{- if $.Values.defaultRouting.rewriteUrlPrefix.enabled }}
    rewrite:
      uri: {{ required "rewriteUri is required" $.Values.defaultRouting.rewriteUrlPrefix.replaceWith }}
{{- end}}

{{- end -}}
