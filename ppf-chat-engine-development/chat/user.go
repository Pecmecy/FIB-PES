package chat

import (
	"encoding/json"
	"fmt"

	db "github.com/pes2324q2-gei-upc/ppf-chat-engine/persist"
)

// User is the struct that will contain the information for a user that belongs at least to one room.
type User struct {
	Id     string      `json:"id"`
	Name   string      `json:"username"`
	Client *Client     `json:"-"` // Web socket client that will use the user when connecting to the chat engine.
	Engine *ChatEngine `json:"-"`

	Rooms map[string]bool `json:"-"`
}

func (u *User) GetRooms() []*Room {
	rooms := make([]*Room, 0, len(u.Rooms))
	for id := range u.Rooms {
		rooms = append(rooms, u.Engine.Rooms[id])
	}
	return rooms
}

func (u *User) UnmarshalJSON(data []byte) error {
	type Alias User
	aux := &struct {
		Id   int    `json:"id"`
		Name string `json:"username"`
		*Alias
	}{
		Alias: (*Alias)(u),
	}
	if err := json.Unmarshal(data, &aux); err != nil {
		return err
	}
	u.Id = fmt.Sprintf("%d", aux.Id)
	u.Name = aux.Name

	if u.Rooms == nil {
		u.Rooms = make(map[string]bool)
	}

	return nil
}

func NewUser(id string, name string, client *Client) *User {
	return &User{
		Id:     id,
		Name:   name,
		Client: client,
		Rooms:  make(map[string]bool),
	}
}

type UserGateway struct {
	Repo db.UserRepository
}

func (gw UserGateway) UserRecordToUser(record db.User) User {
	return User{
		Id:     record.Pk(),
		Name:   record.Name,
		Client: nil,
	}
}

func (gw UserGateway) UserToUserRecord(user User) db.User {
	return db.User{
		Id:   user.Id,
		Name: user.Name,
	}
}

func (gw UserGateway) Exists(pk string) bool {
	return gw.Repo.Exists(pk)
}

func (gw UserGateway) Create(user *User) error {
	userr := gw.UserToUserRecord(*user)
	return gw.Repo.Create(userr)
}

func (gw UserGateway) Read(pk string) *User {
	userr := *gw.Repo.Read(pk)
	user := gw.UserRecordToUser(userr)
	return &user

}

func (gw UserGateway) ReadAll() []*User {
	userrs := gw.Repo.ReadAll()
	users := make([]*User, 0)
	for _, u := range userrs {
		user := gw.UserRecordToUser(*u)
		users = append(users, &user)
	}
	return users
}

func (gw UserGateway) Update(pk string, user *User) error {
	return nil
}

func (gw UserGateway) Delete(pk string) {
	gw.Repo.Delete(pk)
}
