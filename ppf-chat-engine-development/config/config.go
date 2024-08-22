package config

import (
	"net/url"
	"os"

	"github.com/pes2324q2-gei-upc/ppf-chat-engine/auth"
)

type Configuration struct {
	Debug       bool
	UserApiUrl  url.URL
	RouteApiUrl url.URL
	Credentials auth.TokenAuthenticator
}

func GetEnv(key, fallback string) string {
	value, ok := os.LookupEnv(key)
	if !ok {
		value = fallback
	}
	return value
}
