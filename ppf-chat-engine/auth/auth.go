// This file contains functions to authenticate the service with the other services.
package auth

type TokenAuthenticator interface {
	Login() error
	Token() string
}
