{{/*
Expand the name of the chart.
*/}}
{{- define "k8s-job.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "k8s-job.fullname" -}}
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
{{- define "k8s-job.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "k8s-job.labels" -}}
helm.sh/chart: {{ include "k8s-job.chart" . }}
{{ include "k8s-job.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "k8s-job.selectorLabels" -}}
app.kubernetes.io/name: {{ include "k8s-job.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Job-specific labels (includes job name component)
*/}}
{{- define "k8s-job.jobLabels" -}}
{{ include "k8s-job.labels" . }}
app.kubernetes.io/component: {{ .jobName }}
{{- end }}

{{/*
Create job full name (release-jobname)
*/}}
{{- define "k8s-job.jobFullname" -}}
{{- $baseName := include "k8s-job.fullname" .root }}
{{- printf "%s-%s" $baseName .jobName | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Merge job config with defaults
Returns the merged configuration for a specific job
Usage: {{ include "k8s-job.mergeJobConfig" (dict "root" . "jobName" $jobName "jobConfig" $jobConfig) }}
*/}}
{{- define "k8s-job.mergeJobConfig" -}}
{{- $defaults := .root.Values.jobDefaults }}
{{- $job := .jobConfig }}
{{- $merged := dict }}

{{/* Merge image */}}
{{- $defaultImage := $defaults.image | default dict }}
{{- $jobImage := $job.image | default dict }}
{{- $_ := set $merged "image" (merge $jobImage $defaultImage) }}

{{/* Merge simple values with defaults */}}
{{- $_ := set $merged "ttlSecondsAfterFinished" ($job.ttlSecondsAfterFinished | default $defaults.ttlSecondsAfterFinished) }}
{{- $_ := set $merged "backoffLimit" ($job.backoffLimit | default $defaults.backoffLimit) }}
{{- $_ := set $merged "completions" ($job.completions | default $defaults.completions) }}
{{- $_ := set $merged "parallelism" ($job.parallelism | default $defaults.parallelism) }}

{{/* Merge argocd config */}}
{{- $defaultArgocd := $defaults.argocd | default dict }}
{{- $jobArgocd := $job.argocd | default dict }}
{{- $_ := set $merged "argocd" (merge $jobArgocd $defaultArgocd) }}

{{/* Merge container config */}}
{{- $_ := set $merged "command" ($job.command | default $defaults.command) }}
{{- $_ := set $merged "args" ($job.args | default $defaults.args) }}
{{- $_ := set $merged "workingDir" ($job.workingDir | default $defaults.workingDir) }}
{{- $_ := set $merged "env" ($job.env | default $defaults.env) }}
{{- $_ := set $merged "envFrom" ($job.envFrom | default $defaults.envFrom) }}

{{/* Merge resources */}}
{{- $defaultResources := $defaults.resources | default dict }}
{{- $jobResources := $job.resources | default dict }}
{{- $_ := set $merged "resources" (merge $jobResources $defaultResources) }}

{{/* Merge security contexts */}}
{{- $_ := set $merged "podSecurityContext" ($job.podSecurityContext | default $defaults.podSecurityContext) }}
{{- $_ := set $merged "securityContext" ($job.securityContext | default $defaults.securityContext) }}

{{/* Merge scheduling */}}
{{- $_ := set $merged "nodeSelector" ($job.nodeSelector | default $defaults.nodeSelector) }}
{{- $_ := set $merged "tolerations" ($job.tolerations | default $defaults.tolerations) }}
{{- $_ := set $merged "affinity" ($job.affinity | default $defaults.affinity) }}

{{/* Merge volumes */}}
{{- $_ := set $merged "volumes" ($job.volumes | default $defaults.volumes) }}
{{- $_ := set $merged "volumeMounts" ($job.volumeMounts | default $defaults.volumeMounts) }}

{{/* Merge serviceAccount - check job-level create first, then default */}}
{{- $defaultSA := $defaults.serviceAccount | default dict }}
{{- $jobSA := $job.serviceAccount | default dict }}
{{- $mergedSA := dict }}
{{- $_ := set $mergedSA "annotations" ($jobSA.annotations | default $defaultSA.annotations | default dict) }}
{{/* For create, check if explicitly set in the original jobConfig (before any helm merging) */}}
{{- $saCreate := $defaultSA.create }}
{{- if hasKey $jobSA "create" }}
{{- $saCreate = $jobSA.create }}
{{- end }}
{{- $_ := set $mergedSA "create" $saCreate }}
{{- $_ := set $merged "serviceAccount" $mergedSA }}

{{/* Merge RBAC - handle boolean fields explicitly */}}
{{- $defaultRbac := $defaults.rbac | default dict }}
{{- $jobRbac := $job.rbac | default dict }}
{{- $mergedRbac := merge $jobRbac $defaultRbac }}
{{- if hasKey $jobRbac "create" }}
{{- $_ := set $mergedRbac "create" $jobRbac.create }}
{{- end }}
{{- if hasKey $jobRbac "clusterScope" }}
{{- $_ := set $mergedRbac "clusterScope" $jobRbac.clusterScope }}
{{- end }}
{{- $_ := set $merged "rbac" $mergedRbac }}

{{/* Merge externalSecret - handle boolean enabled field explicitly */}}
{{- $defaultES := $defaults.externalSecret | default dict }}
{{- $jobES := $job.externalSecret | default dict }}
{{- $mergedES := dict }}
{{/* Handle enabled boolean */}}
{{- $esEnabled := $defaultES.enabled }}
{{- if hasKey $jobES "enabled" }}
{{- $esEnabled = $jobES.enabled }}
{{- end }}
{{- $_ := set $mergedES "enabled" $esEnabled }}
{{/* Merge other fields */}}
{{- $_ := set $mergedES "name" ($jobES.name | default $defaultES.name) }}
{{- $_ := set $mergedES "refreshInterval" ($jobES.refreshInterval | default $defaultES.refreshInterval) }}
{{- $_ := set $mergedES "refreshPolicy" ($jobES.refreshPolicy | default $defaultES.refreshPolicy) }}
{{- $_ := set $mergedES "creationPolicy" ($jobES.creationPolicy | default $defaultES.creationPolicy) }}
{{- $_ := set $mergedES "deletionPolicy" ($jobES.deletionPolicy | default $defaultES.deletionPolicy) }}
{{/* Merge secretStoreRef */}}
{{- $defaultStoreRef := $defaultES.secretStoreRef | default dict }}
{{- $jobStoreRef := $jobES.secretStoreRef | default dict }}
{{- $_ := set $mergedES "secretStoreRef" (merge $jobStoreRef $defaultStoreRef) }}
{{/* Merge dataFrom */}}
{{- $defaultDataFrom := $defaultES.dataFrom | default dict }}
{{- $jobDataFrom := $jobES.dataFrom | default dict }}
{{- $mergedDataFrom := dict }}
{{- $_ := set $mergedDataFrom "path" ($jobDataFrom.path | default $defaultDataFrom.path) }}
{{- $_ := set $mergedDataFrom "regexp" ($jobDataFrom.regexp | default $defaultDataFrom.regexp) }}
{{- $defaultRewrite := $defaultDataFrom.rewrite | default dict }}
{{- $jobRewrite := $jobDataFrom.rewrite | default dict }}
{{- $_ := set $mergedDataFrom "rewrite" (merge $jobRewrite $defaultRewrite) }}
{{- $_ := set $mergedES "dataFrom" $mergedDataFrom }}
{{- $_ := set $merged "externalSecret" $mergedES }}

{{- $merged | toJson }}
{{- end }}
