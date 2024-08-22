package auth

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
)

type UserApiCredentials struct {
	AuthUrl  *url.URL
	Email    string `json:"email"`
	Password string `json:"password"`
	token    *string
}

func bytesReader(b []byte) io.Reader {
	return bytes.NewReader(b)
}

func (creds *UserApiCredentials) newLoginRequest() (*http.Response, error) {
	bytes, err := json.Marshal(creds)
	if err != nil {
		return nil, fmt.Errorf("could not marshal credentials: %w", err)
	}
	return http.Post(
		creds.AuthUrl.String()+"/", // HACK our UserAPI does not accept urls without trailing /
		"application/json",
		bytesReader(bytes),
	)
}

func (creds *UserApiCredentials) Login() error {
	response, err := creds.newLoginRequest()
	if err != nil {
		return fmt.Errorf("could not build login request: %w", err)
	}
	defer response.Body.Close()
	body, _ := io.ReadAll(response.Body)
	if response.StatusCode != http.StatusOK {
		log.Fatalf("login request not ok: %s", string(body))
	}
	t := struct {
		Token string `json:"token"`
	}{}
	if err := json.Unmarshal(body, &t); err != nil {
		return fmt.Errorf("could not unmarshall token: %w", err)
	}
	creds.token = &t.Token
	return nil
}

func (creds *UserApiCredentials) Token() string {
	if creds.token == nil {
		log.Printf("warning: tried to use empty token")
		return ""
	}
	return *creds.token
}

func GetEnv(key, fallback string) string {
	value, ok := os.LookupEnv(key)
	if !ok {
		value = fallback
	}
	return value
}

func CheckUserToken(token string) (int, error) {
	userSvc, err := url.Parse(GetEnv("USER_API_URL", "http://localhost:8081"))
	if err != nil {
		log.Fatal(err)
	}
	req, err := http.NewRequest(http.MethodGet, userSvc.String()+"/users/self/", nil)
	if err != nil {
		return http.StatusInternalServerError, fmt.Errorf("could not build check request: %w", err)
	}
	req.Header.Add("Authorization", "Token "+token)
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return http.StatusInternalServerError, fmt.Errorf("could not perform check request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return resp.StatusCode, fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}
	return resp.StatusCode, nil
}
