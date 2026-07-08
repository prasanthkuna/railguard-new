package logger

import (
	"os"
	"time"

	"github.com/rs/zerolog"
)

func New() zerolog.Logger {
	return zerolog.New(os.Stdout).With().Timestamp().Str("service", "signgate").Logger()
}

func WithRequestID(log zerolog.Logger, requestID string) zerolog.Logger {
	return log.With().Str("requestId", requestID).Logger()
}

func LatencyField(start time.Time) int64 {
	return time.Since(start).Milliseconds()
}
