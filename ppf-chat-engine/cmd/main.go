// main is the entry point of the ppf-chat-engine application.
// It parses command line flags, registers API handlers, and starts the HTTP server.
package main

import (
	"flag"
	"log"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/pes2324q2-gei-upc/ppf-chat-engine/api"
	"github.com/pes2324q2-gei-upc/ppf-chat-engine/chat"
	_ "github.com/pes2324q2-gei-upc/ppf-chat-engine/docs"
	"github.com/pes2324q2-gei-upc/ppf-chat-engine/persist"
	swag "github.com/swaggo/http-swagger/v2"
)

// @title		Chat Engine API
// @BasePath	/
func main() {
	if err := Run(); err != nil {
		log.Fatal("fatal:%w", err)
	}
}

func Run() error {
	addr := flag.String("addr", "localhost:8083", "http service address")
	dbPath := flag.String("db", "chat.db", "database path")
	flag.Parse()

	db := persist.Init(*dbPath)
	engine, err := chat.NewDefaultChatEngine(db)
	if err != nil {
		return err
	}

	router := mux.NewRouter()
	ctrl := api.NewChatController(router, engine)

	// Swagger documentation route
	ctrl.Router.PathPrefix("/swagger").Handler(swag.Handler(
		swag.URL("http://localhost:8083/swagger/doc.json"),
	)).Methods(http.MethodGet)

	go ctrl.Engine.Server.Run()

	http.Handle("/", ctrl.Router)
	log.Printf("info: starting server on %s", *addr)
	return http.ListenAndServe(*addr, nil)
}
