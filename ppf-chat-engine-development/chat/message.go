package chat

import (
	"encoding/json"
	"time"

	db "github.com/pes2324q2-gei-upc/ppf-chat-engine/persist"
)

type MessageKey struct {
	room   string
	sender string
}

type Message struct {
	CreatedAt time.Time `json:"created_at"`
	Content   string    `json:"content"`
	Room      Room      `json:"room"`
	Sender    User      `json:"sender"`
}

func (m *Message) MarshalJSON() ([]byte, error) {
	return json.Marshal(&struct {
		Ts      string `json:"ts"`
		Content string `json:"content"`
		Room    string `json:"room"`
		Sender  string `json:"sender"`
	}{
		Ts:      m.CreatedAt.Format(time.RFC3339),
		Content: m.Content,
		Room:    m.Room.Id,
		Sender:  m.Sender.Id,
	})
}

// MessageGateway acts as a data mapper between the domain layer and de data layer, transforming the data from the database into domain objects and vice versa.
type MessageGateway struct {
	Repo db.Repository[db.MessageKey, db.Message]
}

func (gw MessageGateway) MessageRecordToMessage(record db.Message) Message {
	return Message{
		CreatedAt: record.CreatedAt,
		Content:   record.Content,
		Room:      Room{Id: record.RoomID},
		Sender:    User{Id: record.SenderID},
	}
}

func (gw MessageGateway) MessageToMessageRecord(msg Message) db.Message {
	r := RoomGateway{}.RoomToRoomRecord(msg.Room)
	u := UserGateway{}.UserToUserRecord(msg.Sender)
	return db.Message{
		Room:    r,
		Sender:  u,
		Content: msg.Content,
	}
}

func (gw MessageGateway) Exists(pk MessageKey) bool {
	key := db.MakeMessageKey(pk.room, pk.sender)
	return gw.Repo.Exists(key)
}

func (gw MessageGateway) Create(room *Message) error {
	msgr := gw.MessageToMessageRecord(*room)
	return gw.Repo.Create(msgr)
}

func (gw MessageGateway) Read(pk MessageKey) *Message {
	key := db.MakeMessageKey(pk.room, pk.sender)
	msgr := gw.Repo.Read(key)
	room := gw.MessageRecordToMessage(msgr)
	return &room

}

func (gw MessageGateway) ReadAll() []*Message {
	msgrs := gw.Repo.ReadAll()
	rooms := make([]*Message, 0)
	for _, u := range msgrs {
		room := gw.MessageRecordToMessage(u)
		rooms = append(rooms, &room)
	}
	return rooms
}

func (gw MessageGateway) Update(pk MessageKey, user *Message) error {
	return nil
}

func (gw MessageGateway) Delete(pk MessageKey) {
	key := db.MakeMessageKey(pk.room, pk.sender)
	gw.Repo.Delete(key)
}

func (gw MessageGateway) FindByRoom(room string) []*Message {
	msgrs, err := gw.Repo.(db.MessageRepository).GetByRoom(db.Room{Id: room})
	if err != nil {
		return nil
	}
	rooms := make([]*Message, 0)
	for _, u := range msgrs {
		room := gw.MessageRecordToMessage(u)
		rooms = append(rooms, &room)
	}
	return rooms
}
