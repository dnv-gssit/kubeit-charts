{{/*
Expand the name of the chart.
*/}}
{{- define "kubeit-rabbit-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kubeit-rabbit-chart.fullname" -}}
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
{{- define "kubeit-rabbit-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kubeit-rabbit-chart.labels" -}}
helm.sh/chart: {{ include "kubeit-rabbit-chart.chart" . }}
{{ include "kubeit-rabbit-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kubeit-rabbit-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ printf "%s-%s" .Release.Name .Values.tenantName | quote }}
app.kubernetes.io/component: {{ default .Release.Name .Values.component }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kubeit-rabbit-chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kubeit-rabbit-chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{- define "rabbitmq.volumeMounts" -}}
  volumeMounts:
    - mountPath: /var/lib/rabbitmq/mnesia/
      name: {{ .Values.spec.override.statefulSet.spec.template.spec.containers.volumeMounts.name  }}
{{- end -}}

{{- define "rabbitmq.initVolumeMounts" -}}
  volumeMounts:
    - mountPath: /var/lib/rabbitmq/mnesia/
      name: {{ .Values.spec.override.statefulSet.spec.template.spec.initContainers.volumeMounts.name }}
{{- end -}}


{{/*
Virtual Service Host
*/}}

{{- define "internaldns.host" -}}
{{ printf "rabbitmq-%s-%s.%s.%s.%s.%s" .Values.tenantName .Release.Name .Values.clusterColour .Values.shortRegion .Values.env .Values.internalDnsDomain }}
{{- end -}}

{{/*
StorageClass name

StorageClass is cluster-scoped, so its name must be unique across namespaces.
Allow overriding to support a single per-tenant StorageClass managed outside this chart.
*/}}
{{- define "kubeit-rabbit-chart.storageClassName" -}}
{{- if .Values.persistentVolume.storageClass.name }}
{{- .Values.persistentVolume.storageClass.name | trunc 63 | trimSuffix "-" | lower }}
{{- else if (default false .Values.persistentVolume.storageClass.perRelease) }}
{{- printf "azurefile-csi-%s-%s-rmq" .Values.tenantName .Release.Name | trunc 63 | trimSuffix "-" | lower }}
{{- else }}
{{- /* Backwards compatible default (legacy): per-tenant StorageClass name */ -}}
{{- printf "azurefile-csi-%s-rmq" .Values.tenantName | trunc 63 | trimSuffix "-" | lower }}
{{- end }}
{{- end }}

{{/*
Azure File shareNamePrefix must be lowercase and should be stable + unique per release.
Keep it short to avoid Azure name length limits.
*/}}
{{- define "kubeit-rabbit-chart.shareNamePrefix" -}}
{{- $raw := printf "rmq-%s-%s" .Values.tenantName .Release.Name -}}
{{- $sanitized := $raw | lower | replace "_" "-" | replace "." "-" -}}
{{- $trimmed := $sanitized | trunc 48 | trimPrefix "-" | trimSuffix "-" -}}
{{- if lt (len $trimmed) 3 -}}
rmq
{{- else -}}
{{- $trimmed -}}
{{- end -}}
{{- end }}
