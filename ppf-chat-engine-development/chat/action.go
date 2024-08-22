package chat

import (
	"encoding/json"
	"errors"
)

const (
	SendMessageCmd     = "SendMessage"
	GetRoomsCmd        = "GetRooms"
	GetRoomMessagesCmd = "GetRoomMessages"
	StoredMessage      = "StoredMessage"

	SendMessageAckContent  = `{"status":"ok", "message":"sent"}`
	MessageNotFoundContent = `{"status":"error","message":"room not found"}`
	NotImplementedContent  = `{"status":"error","message":"not implemented"}`
)

var (
	ErrMessageMalformed = errors.New("message is malformed")
	ErrUnknownCommand   = errors.New("unknown command")
)

type Action struct {
	MessageId string `json:"messageId"`
	Command   string `json:"command"`
	Content   any    `json:"content"`
	Room      string `json:"room"`
	Sender    string `json:"sender"`
}

func (msg *Action) UnmarshalJSON(data []byte) error {
	type Alias Action
	aux := &struct {
		*Alias
	}{
		Alias: (*Alias)(msg),
	}

	// Unmarshal the JSON data into the auxiliary structure to avoid infinite recursion
	if err := json.Unmarshal(data, &aux); err != nil {
		return err
	}

	if msg.MessageId == "" {
		return ErrNoMessageId
	}
	// Check if non-optional fields are empty based on the command
	switch msg.Command {
	case SendMessageCmd:
		// For SendMessage, all fields are required
		if msg.Content == "" || msg.Room == "" || msg.Sender == "" {
			return ErrMessageMalformed
		}
	case GetRoomsCmd:
		// For GetMessages, only sender is required
		if msg.Sender == "" {
			return ErrMessageMalformed
		}
	case GetRoomMessagesCmd:
		// For GetRoom Messages, all fields are required
		if msg.Room == "" || msg.Sender == "" {
			return ErrMessageMalformed
		}
	default:
		return ErrUnknownCommand
	}
	return nil
}

func (msg *Action) Json() ([]byte, error) {
	return json.Marshal(msg)
}

// {
// 	"messageId":"123",
// 	"command":"",
// 	"content":"",
// 	"room":"",
// 	"sender":"1"
// }
