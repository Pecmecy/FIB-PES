// Description: This file contains the API server implementation.

package api

import (
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/pes2324q2-gei-upc/ppf-chat-engine/auth"
	"github.com/pes2324q2-gei-upc/ppf-chat-engine/chat"
)

// ChatApiController is a controller for handling API requests to perform operations on the chat engine.
type ChatApiController struct {
	Router *mux.Router
	Engine *chat.ChatEngine
}

type PostRoomRequest struct {
	Id     string `json:"id"`
	Driver string `json:"driver"`
	Name   string `json:"name"`
}

type PostJoinRequest struct {
	Id     string `json:"id"`
	Driver string `json:"driver"`
}

type PostLeaveRequest struct {
	Id     string `json:"id"`
	Driver string `json:"driver"`
}

// parseRequestBody reads and parses the request body into the provided value.
func parseRequestBody(r *http.Request, v any) error {
	defer r.Body.Close()
	body, _ := io.ReadAll(r.Body)
	if err := json.Unmarshal(body, v); err != nil {
		return err
	}
	return nil
}

// Root handles the request to the home route.
// It always returns a 200 status code.
//
//	@Summary	always returns 200
//	@Tags		endpoints
//	@Accept		json
//	@Produce	json
//	@Success	200	{object}	any
//	@Router		/ [get]
func (ctrl *ChatApiController) Root(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
}

// Connect handles the request to open a connection.
// It promotes an HTTP request to a WebSocket connection.
//
//	@Summary		opens a connection
//	@Description	promotes an http request to a websocket connection
//	@Tags			endpoints
//	@Accept			json
//	@Produce		json
//	@Success		200	{object}	any
//	@Router			/connect/{userId} [get]
func (ctrl *ChatApiController) Connect(w http.ResponseWriter, r *http.Request) {
	id, ok := mux.Vars(r)["userId"]
	if !ok {
		log.Print("error: missing user ID")
	}

	// Get the token from the uri as a query param
	token := r.URL.Query().Get("token")
	if token == "" {
		log.Print("error: missing token")
		http.Error(w, "missing token", http.StatusUnauthorized)
		return
	}
	// Send request to user service to check if the user exists and the token provided is valid
	status, err := auth.CheckUserToken(token)
	if status != http.StatusOK {
		log.Printf("error: %v", err)
		http.Error(w, err.Error(), status)
		return
	}

	// If the user does not exist on the engine, load it.
	if !ctrl.Engine.Exists(id) {
		if err := ctrl.Engine.InitUser(id); err != nil {
			log.Printf("%v", err)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	}
	if err := ctrl.Engine.ConnectUser(id, w, r); err != nil {
		if errors.Is(err, chat.ErrUserNotFound) {
			log.Printf("%v", err)
			http.Error(w, err.Error(), http.StatusNotFound)
			return
		}
		log.Printf("%v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
	log.Printf("User %s connected", id)
}

// CreateRoom handles the request to open a new room.
// It opens a new room and joins the specified driver.
//
//	@Summary		opens a new room
//	@Description	opens a new room and joins the specified driver
//	@Tags			endpoints
//	@Accept			json
//	@Produce		json
//	@Param			data	body	api.PostRoomRequest	true	"room data"
//	@Router			/room [post]
func (ctrl *ChatApiController) CreateRoom(w http.ResponseWriter, r *http.Request) {
	room := &PostRoomRequest{}
	// Parse request body
	if err := parseRequestBody(r, room); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	// Create room
	ctrl.Engine.OpenRoom(room.Id, room.Name, room.Driver)
	// Join user to room
	if !ctrl.Engine.Exists(room.Driver) {
		ctrl.Engine.InitUser(room.Driver)
	}
	ctrl.Engine.JoinRoom(room.Id, room.Driver)
	w.WriteHeader(http.StatusCreated)
}

// JoinRoom handles the request to join a chat room.
// It joins the specified user to the room.
//
//	@Summary	makes user join a room
//	@Tags		endpoints
//	@Accept		json
//	@Produce	json
//	@Param		data	body	api.PostJoinRequest	true	"room data"
//	@Router		/join [post]
func (ctrl *ChatApiController) JoinRoom(w http.ResponseWriter, r *http.Request) {
	room := &PostJoinRequest{}
	// Parse request body
	if err := parseRequestBody(r, room); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	// Join user to room
	if !ctrl.Engine.Exists(room.Driver) {
		ctrl.Engine.InitUser(room.Driver)
	}
	ctrl.Engine.JoinRoom(room.Id, room.Driver)
	w.WriteHeader(http.StatusOK)
}

// LeaveRoom handles the request to leave a chat room.
// It removes the specified user from the room.
//
//	@Summary	makes user leave a room
//	@Tags		endpoints
//	@Accept		json
//	@Produce	json
//	@Param		data	body		api.PostLeaveRequest	true	"room data"
//	@Success	200		{object}	any
//	@Router		/leave [post]
func (ctrl *ChatApiController) LeaveRoom(w http.ResponseWriter, r *http.Request) {
	room := &PostLeaveRequest{}
	// Parse request body
	if err := parseRequestBody(r, room); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	// Leave user from room
	ctrl.Engine.LeaveRoom(room.Id, room.Driver)
	w.WriteHeader(http.StatusOK)
}

// GetRoomMessages handles the request to get the messages of a room.
// It returns the messages of the specified room.
//
//	@Summary		gets messages of a room
//	@Tags			endpoints
//	@Accept			json
//	@Produce		json
//	@Param			id	path	string	true	"room id"
//	@Success		200	{object}	chat.Message
//	@Router			/room/{id}/messages [get]
func (ctrl *ChatApiController) GetRoomMessages(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	messages := ctrl.Engine.GetRoomMessages(id)
	json.NewEncoder(w).Encode(messages)
	w.WriteHeader(http.StatusOK)
}

// NewChatController creates a new instance of ChatApiController.
func NewChatController(router *mux.Router, engine *chat.ChatEngine) *ChatApiController {
	ctrl := &ChatApiController{
		Router: mux.NewRouter(),
		Engine: engine,
	}
	log.Println("info: registering API s")
	ctrl.Router.HandleFunc("/", ctrl.Root).Methods(http.MethodGet)
	ctrl.Router.HandleFunc("/connect/{userId}", ctrl.Connect).Methods(http.MethodGet)
	ctrl.Router.HandleFunc("/room", ctrl.CreateRoom).Methods(http.MethodPost)
	ctrl.Router.HandleFunc("/room/{id}/messages", ctrl.GetRoomMessages).Methods(http.MethodGet)
	ctrl.Router.HandleFunc("/join", ctrl.JoinRoom).Methods(http.MethodPost)
	ctrl.Router.HandleFunc("/leave", ctrl.LeaveRoom).Methods(http.MethodPost)

	// TODO	ctrl.Router.HandleFunc("/room/<id>/messages").Methods(http.MethodGet)
	// TODO ctrl.Router.HandleFunc("/room").Methods(http.MethodGet)
	return ctrl
}
