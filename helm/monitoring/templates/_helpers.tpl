{{/*
Expand the name of the chart.
*/}}
{{- define "listapro-monitoring.fullname" -}}
{{- printf "%s-%s" .Release.Name "monitoring" | trunc 63 | trimSuffix "-" -}}
{{- end -}} 