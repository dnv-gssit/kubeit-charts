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
{{- if .Values.appVersion }}
app.kubernetes.io/version: {{ .Values.appVersion }}
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
app.kubernetes.io/name: {{ include "services-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the serviceaccount to use
*/}}
{{- define "services-chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.enabled }}
{{- default (include "services-chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the configMap to use
*/}}
{{- define "services-chart.configMapName" -}}
{{- if .Values.configMap.enabled }}
{{- default (include "services-chart.fullname" .) .Values.configMap.name }}
{{- else }}
{{- default "default" .Values.configMap.name }}
{{- end }}
{{- end }}

{{/*
Create the automatic external FQDN for virtualService
*/}}
{{- define "services-chart.autoFQDNexternal" -}}
{{- if (hasKey .Values "kubeit") -}}
{{- if and (hasKey .Values.kubeit "dnsDomain") (hasKey .Values.kubeit "shortRegion") (hasKey .Values.kubeit "clusterColour") (hasKey .Values.kubeit "env") -}}
{{- if eq .Values.kubeit.clusterColour (default "" .Values.kubeit.clusterSubdomain) -}}
{{- printf "%s.%s.%s" (default .Release.Name .Values.app) .Values.kubeit.clusterColour .Values.kubeit.dnsDomain -}}
{{- else -}}
{{- printf "%s.%s.%s.%s.%s" (default .Release.Name .Values.app) .Values.kubeit.clusterColour .Values.kubeit.shortRegion .Values.kubeit.env .Values.kubeit.dnsDomain -}}
{{- end -}}
{{- else -}}
{{- fail "kubeit.dnsDomain and kubeit.shortRegion and kubeit.clusterColour and kubeit.env are required" }}
{{- end -}}
{{- else -}}
{{- fail "kubeit is required" }}
{{- end }}
{{- end }}

{{/*
Create the automatic internal FQDN for virtualService
*/}}
{{- define "services-chart.autoFQDNinternal" -}}
{{- if (hasKey .Values "kubeit") -}}
{{- if and (hasKey .Values.kubeit "internalDnsDomain") (hasKey .Values.kubeit "shortRegion") (hasKey .Values.kubeit "clusterColour") (hasKey .Values.kubeit "env") -}}
{{- if eq .Values.kubeit.clusterColour (default "" .Values.kubeit.clusterSubdomain) -}}
{{- printf "%s.%s.%s" (default .Release.Name .Values.app) .Values.kubeit.clusterColour .Values.kubeit.internalDnsDomain -}}
{{- else -}}
{{- printf "%s.%s.%s.%s.%s" (default .Release.Name .Values.app) .Values.kubeit.clusterColour .Values.kubeit.shortRegion .Values.kubeit.env .Values.kubeit.internalDnsDomain -}}
{{- end -}}
{{- else -}}
{{- fail "kubeit.internalDnsDomain and kubeit.shortRegion and kubeit.clusterColour and kubeit.env are required" }}
{{- end -}}
{{- else -}}
{{- fail "kubeit is required" }}
{{- end }}
{{- end }}

{{/*
Create full FQDN for internal service
*/}}
{{- define "services-chart.fullFQDN" -}}
{{- printf "%s.%s.svc.cluster.local" (include "services-chart.fullname" .) (.Release.Namespace|lower) -}}
{{- end }}

{{/*
Create the content of the virtualService
*/}}
{{- define "services-chart.virtualserviceContent" -}}
{{- if $.Values.defaultRouting.http -}}
http:
{{- range $httpRoute := $.Values.defaultRouting.http }}
{{- toYaml (list $httpRoute) | nindent 2 }}
{{- if $.Values.defaultRouting.retries }}
    retries:
      {{- toYaml $.Values.defaultRouting.retries | nindent 6 }}
{{- end }}
{{- if $.Values.defaultRouting.headers }}
    headers:
      {{- toYaml $.Values.defaultRouting.headers | nindent 6 }}
{{- end }}
{{- end }}
{{- if $.Values.defaultRouting.corsPolicy }}
    corsPolicy:
      {{- toYaml $.Values.defaultRouting.corsPolicy | nindent 6 }}
{{- end }}
{{- else -}}
http:
  - match:
    - uri:
        prefix: /
    route:
      - destination:
          host: {{ include "services-chart.fullFQDN" $ }}
          port:
            number: {{ $.Values.service.port }}
{{- if $.Values.defaultRouting.retries }}
    retries:
      {{- toYaml $.Values.defaultRouting.retries | nindent 6 }}
{{- end }}
{{- if $.Values.defaultRouting.headers }}
    headers:
      {{- toYaml $.Values.defaultRouting.headers | nindent 6 }}
{{- end }}
{{- if $.Values.defaultRouting.corsPolicy }}
    corsPolicy:
      {{- toYaml .Values.defaultRouting.corsPolicy | nindent 6 }}
  {{- end }}
{{- end }}
{{- if $.Values.defaultRouting.tcp }}
tcp:
{{- with $.Values.defaultRouting.tcp }}
{{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
{{- if $.Values.defaultRouting.tls }}
tls:
{{- with $.Values.defaultRouting.tls }}
{{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}
