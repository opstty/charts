{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "hive.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "hive.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if hasPrefix .Release.Name $name }}
{{- $name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "hive.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "hive.labels" -}}
helm.sh/chart: {{ include "hive.chart" . }}
{{ include "hive.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.commonLabels }}
{{ tpl (toYaml .Values.commonLabels) . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "hive.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hive.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use.
*/}}
{{- define "hive.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "hive.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the proper image reference for a given image config dict.
Supports: registry, repository, tag (defaults to .Chart.AppVersion), digest.
Usage: {{ include "hive.image" (dict "image" .Values.image "chart" .Chart) }}
*/}}
{{- define "hive.image" -}}
{{- $image := .image -}}
{{- $chart := .chart -}}
{{- if $image.useRepositoryAsSoleImageReference -}}
  {{- printf "%s" $image.repository -}}
{{- else -}}
  {{- $registry := $image.registry | default "" -}}
  {{- $repo := $image.repository -}}
  {{- $separator := ":" -}}
  {{- $termination := (default $chart.AppVersion $image.tag) | toString -}}
  {{- if $image.digest -}}
    {{- $separator = "@" -}}
    {{- $termination = $image.digest | toString -}}
  {{- end -}}
  {{- if $registry -}}
    {{- printf "%s/%s%s%s" $registry $repo $separator $termination -}}
  {{- else -}}
    {{- printf "%s%s%s" $repo $separator $termination -}}
  {{- end -}}
{{- end -}}
{{- end }}

{{/*
Resolve the effective image for a component.
Merges global image with component-specific overrides (non-empty values win).
Usage: {{ include "hive.componentImage" (dict "global" .Values.image "component" .Values.metastore.image "chart" .Chart) }}
*/}}
{{- define "hive.componentImage" -}}
{{- $global := .global -}}
{{- $comp := .component -}}
{{- $chart := .chart -}}
{{- $resolved := dict
  "registry"    ($comp.registry    | default $global.registry)
  "repository"  ($comp.repository  | default $global.repository)
  "pullPolicy"  ($comp.pullPolicy  | default $global.pullPolicy)
  "tag"         ($comp.tag         | default $global.tag)
  "digest"      ($comp.digest      | default $global.digest)
  "useRepositoryAsSoleImageReference" ($global.useRepositoryAsSoleImageReference)
-}}
{{- include "hive.image" (dict "image" $resolved "chart" $chart) -}}
{{- end }}

{{/*
Merge two lists of env vars by their 'name' key.
Component-level entries override global ones.
Usage: {{ include "hive.mergeEnv" (dict "defaultEnv" .Values.env "specificEnv" .Values.metastore.env) }}
*/}}
{{- define "hive.mergeEnv" -}}
{{- $envMap := dict -}}
{{- range $e := .defaultEnv -}}
  {{- if $e.name -}}
    {{- $_ := set $envMap $e.name $e -}}
  {{- end -}}
{{- end -}}
{{- range $e := .specificEnv -}}
  {{- if $e.name -}}
    {{- $_ := set $envMap $e.name $e -}}
  {{- end -}}
{{- end -}}
{{- if $envMap -}}
  {{- $mergedList := list -}}
  {{- range $name, $value := $envMap -}}
    {{- $mergedList = append $mergedList $value -}}
  {{- end -}}
  {{- toYaml $mergedList -}}
{{- end -}}
{{- end }}

{{/*
Render hive-site.xml content from merged properties.
Usage: {{ include "hive.hiveSiteXml" (dict "default" .Values.hiveSite.properties "override" .Values.hiveserver2.hiveSite.properties) }}
*/}}
{{- define "hive.hiveSiteXml" -}}
{{- $props := mergeOverwrite (.default | default dict) (.override | default dict) -}}
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<configuration>
{{- range $key, $value := $props }}
  <property>
    <name>{{ $key }}</name>
    <value>{{ $value }}</value>
  </property>
{{- end }}
</configuration>
{{- end }}
