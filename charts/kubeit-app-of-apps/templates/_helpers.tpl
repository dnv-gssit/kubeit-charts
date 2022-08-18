{{- define "directories" }}
{{- $envDirectory := "" -}}
{{- if eq $.Values.env "aux" -}}
{{- $envDirectory = "auxiliary" -}}
{{- else -}}
{{- $envDirectory = $.Values.env -}}
{{- end -}}
{{- printf "%s" $envDirectory -}}
{{- end -}}

{{- define "globalScope" }}
{{- printf "appValues/%s/appGlobal.yaml" .appName -}}
{{- end -}}

{{- define "envScope" }}
{{- printf "appValues/%s/environment/%s/%s.yaml" .appName .envDirectory .envDirectory | trim -}}
{{- end -}}

{{- define "regionScope" }}
{{- printf "appValues/%s/environment/%s/region/%s/%s.yaml" .appName .envDirectory .region .region -}}
{{- end -}}

{{- define "clusterScope" }}
{{- printf "appValues/%s/environment/%s/region/%s/cluster/%s.yaml" .appName .envDirectory .region .clusterColour -}}
{{- end -}}

{{- define "valuesList" }}
{{- $globalScope := include "globalScope" (dict "appName" .appName) -}}
{{- $envScope := include "envScope" (dict "appName" .appName "envDirectory" .envDirectory) -}}
{{- $regionScope := include "regionScope" (dict "appName" .appName "envDirectory" .envDirectory "region" .region) -}}
{{- $clusterScope := include "clusterScope" (dict "appName" .appName "envDirectory" .envDirectory "region" .region "clusterColour" .clusterColour )}}
{{- $valuesList := list $globalScope $envScope $regionScope $clusterScope }}
{{- mustToJson $valuesList }}
{{- end }}

{{- define "argoCdImageUpdaterVariables" -}}
{{- $enableUpdater := "" }}
{{- $updaterRepo := "" }}
{{- $updaterConstraint := "" }}
{{- $updaterStrategy := "" }}
{{- $updaterPullSecret := "" }}
{{- $updaterAllowTags := "" }}
{{- $updaterIgnoreTags := "" }}
{{- $updaterGitBranch := "" }}
{{- $updaterGitSecret := "" }}
{{ range .valuesList }}
{{ range $.Files.Lines . }}
{{- if eq (contains "argoCDImageUpdater" . ) true }}
{{ $enableUpdater = true }}
{{- else if eq (contains "updaterRepository" . ) true }}
{{ $updaterRepo = "" | regexReplaceAll "\"" . | replace "updaterRepository:" "" | trim }}
{{- else if eq (contains "updaterVersionConstraint" .) true }}
{{ $updaterConstraint = "" | regexReplaceAll "\"" . | replace "updaterVersionConstraint:" "" | trim }}
{{- else if eq (contains "updaterAllowTags" .) true }}
{{ $updaterAllowTags = "" | regexReplaceAll "\"" . | replace "updaterAllowTags:" "" | trim }}
{{- else if eq (contains "updaterIgnoreTags" .) true }}
{{ $updaterIgnoreTags = . | replace "updaterIgnoreTags:" "" | trim }}
{{- else if eq (contains "updaterGitBranch" .) true }}
{{ $updaterGitBranch = "" | regexReplaceAll "\"" . | replace "updaterGitBranch:" "" | trim }}
{{- else if eq (contains "gitSecretName" .) true }}
{{ $updaterGitSecret = "" | regexReplaceAll "\"" . | replace "gitSecretName:" "" | trim }}
{{- else if eq (contains "updaterStrategy" .) true }}
{{ $updaterStrategy = "" | regexReplaceAll "\"" . | replace "updaterStrategy:" "" | trim }}
{{- else if eq (contains "updaterPullSecret" .) true }}
{{ $updaterPullSecret = "" | regexReplaceAll "\"" . | replace "updaterPullSecret:" "" | trim }}
{{- else if eq (contains "updaterGitSecret" .) true }}
{{ $updaterGitSecret = "" | regexReplaceAll "\"" . | replace "updaterGitSecret:" "" | trim }}
{{- end }}
{{- $argoCdImageUpdaterVars := list $updaterRepo $updaterConstraint $updaterAllowTags $updaterIgnoreTags $updaterGitBranch $updaterGitSecret $updaterStrategy $updaterPullSecret $updaterGitSecret -}}
{{- mustToJson $argoCdImageUpdaterVars -}}
{{- end }}
{{- end }}
{{- end -}}