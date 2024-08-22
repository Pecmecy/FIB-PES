package auth

import (
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"
)

func parseURL(rawURL string) *url.URL {
	parsedURL, _ := url.Parse(rawURL)
	return parsedURL
}

func TestUserApiCredentials(t *testing.T) {
	// Create a test server with a mock response
	mockServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"token": "test-token"}`))
	}))
	defer mockServer.Close()

	// Create UserApiCredentials with the mock server URL
	creds := &UserApiCredentials{
		AuthUrl:  parseURL(mockServer.URL),
		Email:    "test@example.com",
		Password: "password",
	}
	t.Run("Login", func(t *testing.T) {
		// Call the Login method
		err := creds.Login()
		if err != nil {
			t.Errorf("Login returned an error: %v", err)
		}
	})
	t.Run("Token", func(t *testing.T) {
		// Check if the token is set correctly
		expectedToken := "test-token"
		if creds.Token() != expectedToken {
			t.Errorf("Token is incorrect, got: %s, want: %s", creds.Token(), expectedToken)
		}
	})
}
