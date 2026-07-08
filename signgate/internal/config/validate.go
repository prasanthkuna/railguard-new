package config

import (
	"fmt"
	"strings"
)

const DevAPIKey = "dev-local-signgate-key"

func (c Config) Validate() error {
	if strings.TrimSpace(c.APIKey) == "" {
		return fmt.Errorf("SIGNGATE_API_KEY is required")
	}
	if !c.IsLocal() {
		if c.APIKey == DevAPIKey {
			return fmt.Errorf("SIGNGATE_API_KEY must not use the dev default in production")
		}
		if strings.TrimSpace(c.RailguardSignerKey) == "" {
			return fmt.Errorf("RAILGUARD_SIGNER_PRIVATE_KEY is required in production")
		}
		if c.WatcherEnabled && isZeroAddress(c.HookAddress) {
			return fmt.Errorf("HOOK_ADDRESS must be set when watcher is enabled in production")
		}
		if isZeroAddress(c.AdapterAddress) {
			return fmt.Errorf("ADAPTER_ADDRESS must be set in production")
		}
	}
	if c.WatcherEnabled && !c.IsLocal() && isZeroAddress(c.HookAddress) {
		return fmt.Errorf("HOOK_ADDRESS must be set when watcher is enabled")
	}
	return nil
}

func isZeroAddress(addr string) bool {
	addr = strings.ToLower(strings.TrimSpace(addr))
	return addr == "" || addr == "0x0000000000000000000000000000000000000000"
}
