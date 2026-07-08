package api

import (
	"crypto/subtle"
	"net/http"
	"strings"
)

// requireAPIKey protects mutating SignGate endpoints from public cosigning abuse.
func requireAPIKey(expected string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if expected == "" {
				http.Error(w, "signgate api key not configured", http.StatusServiceUnavailable)
				return
			}
			got := strings.TrimSpace(r.Header.Get("X-SignGate-API-Key"))
			if got == "" {
				auth := strings.TrimSpace(r.Header.Get("Authorization"))
				if strings.HasPrefix(strings.ToLower(auth), "bearer ") {
					got = strings.TrimSpace(auth[7:])
				}
			}
			if subtle.ConstantTimeCompare([]byte(got), []byte(expected)) != 1 {
				http.Error(w, "unauthorized", http.StatusUnauthorized)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}
