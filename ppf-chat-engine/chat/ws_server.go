package chat

import (
	"log"
	"net/http"

	"github.com/gorilla/websocket"
)

type WsServer struct {
	Engine     *ChatEngine
	Clients    map[*Client]bool
	register   chan *Client
	unregister chan *Client
	store      chan *Action
}

func (server *WsServer) Run() {
	for {
		select {
		case client := <-server.register:
			log.Printf("info: registering client %s", client.User.Id)
			server.Clients[client] = true
		case client := <-server.unregister:
			for room := range client.User.Rooms {
				r := server.Engine.Rooms[room]
				if r.Empty() {
					r.Close()
				}
			}
			client.Close()
			delete(server.Clients, client)
		case msgAction := <-server.store:
			if msgAction.Command != SendMessageCmd {
				break
			}
			r := server.Engine.Rooms[msgAction.Room]
			u := server.Engine.Users[msgAction.Sender]
			msg := Message{
				Content: msgAction.Content.(string),
				Room:    *r,
				Sender:  *u,
			}
			server.Engine.StoreMessage(msg)
		}
	}
}

func (server *WsServer) OpenConnection(w http.ResponseWriter, r *http.Request) *Client {
	var upgrader = websocket.Upgrader{}
	upgrader.CheckOrigin = func(r *http.Request) bool {
		return true // HACK this should not be so... unsafe
	}
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println(err)
		return nil
	}
	client := NewClient(conn, server, nil)
	go client.ReadPump()
	go client.WritePump()
	return client
}

func NewWsServer(engine *ChatEngine) *WsServer {
	return &WsServer{
		Engine:     engine,
		Clients:    make(map[*Client]bool, 64),
		register:   make(chan *Client, 2),
		unregister: make(chan *Client, 2),
	}
}
