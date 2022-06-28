---
{{- define "appLabels" -}}
app: {{ required "app is required" .Values.app }}
app.kubernetes.io/name: {{ include "platform-service.name" . }}
helm.sh/chart: {{ include "platform-service.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
version: {{ .Values.version }}
{{ if $.Values.kubeit }}
tenant: {{ $.Values.kubeit.tenantName }}
{{ if $.Values.volumes -}}
state: stateful
{{- end -}}
{{- end -}}
