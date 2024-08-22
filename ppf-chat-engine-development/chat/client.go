package chat

import (
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/gorilla/websocket"
)

const (
	// Max time allowed to read the next pong msg from the peer
	pongWait   = 20 * time.Second
	pingPeriod = 10 * time.Second

	// Max time allowed to write a message to the peer
	writeWait = 10 * time.Second

	// Max message size allowed from the peer
	maxMessageSize = 512
)

var (
	newLine = []byte{'\n'}
)

// Client represents a WebSocket client.
type Client struct {
	Connection *websocket.Conn
	Server     *WsServer
	User       *User

	// Buffered channel of outbound messages
	send  chan *Action
	close chan bool
}

// Close closes the client connection and unregisters the client from the engine.
func (client *Client) Close() {
	log.Printf("info: closing connection for user %s", client.User.Id)
	time.Sleep(time.Millisecond)
	client.close <- true
	client.User = nil
	close(client.send)
	close(client.close)
}

// ReadPump pump messages from the websocket connection and the client handles them.
func (client *Client) ReadPump() {
	// Setup client connection
	client.Connection.SetReadLimit(maxMessageSize)

	// If a message is not received within 'pongWait' duration, the read operation will return a
	// timeout error therefore asuming the client is disconnected.
	client.Connection.SetReadDeadline(time.Now().Add(pongWait))
	client.Connection.SetPongHandler(func(string) error {
		// Set a deadline for the next read operation from the WebSocket connection.
		client.Connection.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	// Loop to read messages from the WebSocket connection
	for {
		_, msg, err := client.Connection.ReadMessage()
		if err != nil {
			// Log if is unexpected close error
			if websocket.IsCloseError(err, websocket.CloseNoStatusReceived) {
				log.Printf("warn: closed connection: %v", err)
			}
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("error: %v", err)
			}
			client.Server.unregister <- client
			return
		}
		// Send the trimmed message to the engine
		client.HandleMessage(msg)
	}
}

// WritePump pumps messages from the client send channel to the WebSocket connection.
func (client *Client) WritePump() {
	// Start a ticker to send ping messages to the client
	ticker := time.NewTicker(pingPeriod)
	defer ticker.Stop()

	// Loop to write messages to the WebSocket connection
	for {
		select {
		case message, ok := <-client.send:
			// Set a deadline for the next write operation to the WebSocket connection.
			client.Connection.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				// Engine closed the channel
				return
			}
			// Get the writer to write the message to the WebSocket connection and write the message
			writer, err := client.Connection.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			if jsonMsg, err := message.Json(); err != nil {
				writer.Close()
				log.Panicln("panic: %w", err) // Panic if the message can't be marshalled to JSON
			} else {
				writer.Write(jsonMsg)
			}
			// Handle queued messages
			for range len(client.send) {
				message = <-client.send
				if messageJson, err := message.Json(); err != nil {
					writer.Close()
					log.Panicln("panic: %w", err)
				} else {
					writer.Write(newLine)
					writer.Write(messageJson)
				}
			}
			if err := writer.Close(); err != nil {
				log.Panicln("panic: %w", err)
				return
			}
		case <-ticker.C:
			if err := client.Connection.WriteControl(websocket.PingMessage, []byte{}, time.Now().Add(writeWait)); err != nil {
				client.Server.unregister <- client
				return
			}
		}
	}
}

// HandleMessage handles a message depending on the command specified in the message.
func (client *Client) HandleMessage(raw []byte) {
	message := &Action{}
	if err := json.Unmarshal(raw, message); err != nil {
		client.handleError(message, err)
		log.Printf("error: %v", err)
		return
	}

	// If the message sender is not the client user, ignore the message
	if message.Sender != client.User.Id {
		client.handleError(message, ErrWrongMessageSender)
		log.Printf("error: %v", ErrWrongMessageSender)
		return
	}

	switch message.Command {
	case SendMessageCmd:
		client.handleSendMessage(message)
	case GetRoomsCmd:
		client.handleGetRooms(message)
	case GetRoomMessagesCmd:
		client.handleGetRoomMessages(message)
	default:
		client.handleError(message, ErrUnknownCommand)
		log.Printf("error: unknown command %s", message.Command)
	}
}

// Handle a Send Message command by sending the message to the specified room.
func (client *Client) handleSendMessage(message *Action) {
	if room, ok := client.Engine().Rooms[message.Room]; ok {
		room.broadcast <- message
		// ack the message
		ack := *message
		ack.Content = SendMessageAckContent
		client.send <- &ack
		client.Server.store <- message
	} else {
		client.handleError(message, ErrRoomNotFound)
		log.Printf("error: room %s not found", message.Room)
	}
}

// Handle a Get Rooms command by sending the client the rooms the user has joined to.
func (client *Client) handleGetRooms(message *Action) {
	rooms := client.User.GetRooms()
	response := *message
	response.Content = rooms
	client.send <- &response
}

// Handle a Get Room Messages command by sending the client the messages of the specified room.
func (client *Client) handleGetRoomMessages(message *Action) {
	// Send the message to the room
	messages := client.Engine().GetRoomMessages(message.Room)
	response := *message
	response.Content = messages
	client.send <- &response
}

func (client *Client) handleError(message *Action, err error) {
	response := *message
	response.Content = fmt.Sprintf(`{"status":"error","message":"%s"}`, err.Error())
	client.send <- &response
}

func (client *Client) Engine() *ChatEngine {
	return client.Server.Engine
}

// NewClient creates a new Client instance.
func NewClient(connection *websocket.Conn, server *WsServer, user *User) *Client {
	return &Client{
		connection,
		server,
		user,
		make(chan *Action, 256),
		make(chan bool, 1),
	}
}
