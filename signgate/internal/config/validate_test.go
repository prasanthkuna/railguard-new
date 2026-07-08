package config

import "testing"

func TestValidateRejectsDevKeyInProduction(t *testing.T) {
	cfg := Config{AppEnv: "production", APIKey: DevAPIKey}
	if err := cfg.Validate(); err == nil {
		t.Fatal("expected production dev key rejection")
	}
}

func TestValidateAllowsDevKeyLocally(t *testing.T) {
	cfg := Config{AppEnv: "local", APIKey: DevAPIKey}
	if err := cfg.Validate(); err != nil {
		t.Fatal(err)
	}
}

func TestValidateRequiresAPIKey(t *testing.T) {
	cfg := Config{AppEnv: "local"}
	if err := cfg.Validate(); err == nil {
		t.Fatal("expected missing api key error")
	}
}
