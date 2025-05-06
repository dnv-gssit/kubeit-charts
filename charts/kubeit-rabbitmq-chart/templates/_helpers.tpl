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

