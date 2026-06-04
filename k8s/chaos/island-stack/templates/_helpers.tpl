{{/*
Per-tier resource name: "<studentName>-<tier>" — matches the naming the crew
learned on Day 3, so the sabotaged chart looks like their own chart.
Usage:  {{ include "island-stack.name" (dict "ctx" . "tier" "frontend") }}
*/}}
{{- define "island-stack.name" -}}
{{- printf "%s-%s" .ctx.Values.studentName .tier -}}
{{- end -}}
