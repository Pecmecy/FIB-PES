package chat

import (
	"encoding/json"
	"log"

	db "github.com/pes2324q2-gei-upc/ppf-chat-engine/persist"
)

type Room struct {
	Id     string           `json:"id"`
	Name   string           `json:"name"`
	Driver *string          `json:"driver"`
	Users  map[string]*User `json:"users"`

	register   chan *User // Channel for registering/joining a user
	unregister chan *User // Channel for unregistering/leaving a user

	broadcast chan *Action // Channel for broadcasting messages to all users in the room
	close     chan bool    // Channel for closing the room
}

func (room *Room) CloseIfEmpty() {
	if room.Empty() {
		room.Close()
	}
}

func (room *Room) MarshalJSON() ([]byte, error) {
	type Alias Room
	alias := struct {
		Id     string `json:"id"`
		Name   string `json:"name"`
		Driver string `json:"driver"`
		Users  []User `json:"users"`
		*Alias
	}{
		Alias:  (*Alias)(room),
		Id:     room.Id,
		Name:   room.Name,
		Driver: *room.Driver,
		Users:  make([]User, len(room.Users)),
	}
	for _, user := range room.Users {
		alias.Users = append(alias.Users, *user)
	}
	return json.Marshal(&alias)
}

func (room *Room) Run() {
	for {
		select {
		case user := <-room.register:
			room.Register(user)
		case user := <-room.unregister:
			room.Unregister(user)
		case message := <-room.broadcast:
			room.Broadcast(message)
		case <-room.close:
			log.Println("info: closing room")
			return
		}
	}
}

func (room *Room) Register(user *User) {
	room.Users[user.Id] = user
	user.Rooms[room.Id] = true
}

func (room *Room) Unregister(user *User) {
	delete(room.Users, user.Id)
}

func (room *Room) Broadcast(message *Action) {
	for _, user := range room.Users {
		if user.Client != nil && message.Sender != user.Id {
			user.Client.send <- message
		}
	}
}

func (room *Room) Close() {
	room.close <- true
}

func (room *Room) Empty() bool {
	return len(room.Users) == 0
}

func NewRoom(id string, name string, driver *string) *Room {
	return &Room{
		Id:         id,
		Name:       name,
		Driver:     driver,
		Users:      make(map[string]*User, 4),
		register:   make(chan *User, 2),
		unregister: make(chan *User, 2),
		broadcast:  make(chan *Action, 10),
		close:      make(chan bool),
	}
}

type RoomGateway struct {
	Repo db.RoomRepository
}

func (gw RoomGateway) RoomRecordToRoom(record db.Room) Room {
	return Room{
		Id:         record.Pk(),
		Name:       record.Name,
		Driver:     &record.Driver,
		Users:      make(map[string]*User),
		register:   make(chan *User),
		unregister: make(chan *User),
		broadcast:  make(chan *Action),
		close:      make(chan bool),
	}
}

func (gw RoomGateway) RoomToRoomRecord(user Room) db.Room {
	return db.Room{
		Id:     user.Id,
		Name:   user.Name,
		Driver: *user.Driver,
		Users:  make([]*db.User, 0),
	}
}

func (gw RoomGateway) Exists(pk string) bool {
	return gw.Repo.Exists(pk)
}

func (gw RoomGateway) Create(room *Room) error {
	roomr := gw.RoomToRoomRecord(*room)
	return gw.Repo.Create(roomr)
}

func (gw RoomGateway) Read(pk string) *Room {
	roomr := *gw.Repo.Read(pk)
	room := gw.RoomRecordToRoom(roomr)
	return &room

}

func (gw RoomGateway) ReadAll() []*Room {
	roomrs := gw.Repo.ReadAll()
	rooms := make([]*Room, 0)
	for _, u := range roomrs {
		room := gw.RoomRecordToRoom(*u)
		rooms = append(rooms, &room)
	}
	return rooms
}

func (gw RoomGateway) Update(pk string, user *Room) error {
	return nil
}

func (gw RoomGateway) Delete(pk string) {
	gw.Repo.Delete(pk)
}
