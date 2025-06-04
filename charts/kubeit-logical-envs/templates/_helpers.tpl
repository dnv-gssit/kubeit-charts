{{- define "bootstrap.allManifests" }}
{{ include "bootstrap.application" .Values }}
{{- end }}
