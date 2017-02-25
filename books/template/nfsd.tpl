{{range .dirs -}}
{{.path}} {{ range .clients }} {{.ip_range}}({{.options}}) {{ end }}
{{ end -}}
