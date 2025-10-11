package logger

import (
	"log/slog"
	"text/template"

	"github.com/m-mizutani/clog"
)

const clogTemplate = `{{.Level}} {{.Message}}{{ if .FileName }} [{{.FileName}}:{{.FileLine}}]{{ end }} `

var clogLevels = map[slog.Level]string{
	slog.LevelDebug: "DEBUG",
	slog.LevelInfo:  " INFO",
	slog.LevelWarn:  " WARN",
	slog.LevelError: "ERROR",
}

var clogLevelFormatter = func(level slog.Level) string {
	if v, ok := clogLevels[level]; ok {
		return v
	}
	return level.String()
}

func UseColorLog(level slog.Level) {
	tmpl, err := template.New("default").Parse(clogTemplate)
	if err != nil {
		panic(err)
	}

	h := clog.New(
		clog.WithColor(true),
		clog.WithLevel(level),
		clog.WithSource(true),
		clog.WithLevelFormatter(clogLevelFormatter),
		clog.WithTemplate(tmpl),
	)
	l := slog.New(h)
	slog.SetDefault(l)
}
func init() {
	UseColorLog(slog.LevelDebug)
}
