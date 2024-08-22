package config

import (
	"os"
	"testing"
)

func TestGetEnv(t *testing.T) {
	// Test case for when the environment variable exists
	t.Run("Env var exists", func(t *testing.T) {
		key := "EXISTING_ENV_VAR"
		value := "existing_value"
		os.Setenv(key, value)
		defer os.Unsetenv(key)

		result := GetEnv(key, "fallback_value")
		if result != value {
			t.Errorf("Expected %s, got %s", value, result)
		}
	})

	// Test case for when the environment variable does not exist
	t.Run("Env var not exist", func(t *testing.T) {
		key := "NON_EXISTING_ENV_VAR"
		fallback := "fallback_value"

		result := GetEnv(key, fallback)
		if result != fallback {
			t.Errorf("Expected %s, got %s", fallback, result)
		}
	})
}
