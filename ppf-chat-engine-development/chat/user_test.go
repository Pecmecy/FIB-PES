package chat

import (
	"testing"
)

func Test_GetRooms(t *testing.T) {
	// Init a room
	room := &Room{
		Id:   "1",
		Name: "test",
	}
	// Init a user and a mock chat engine with the declared room
	user := &User{
		Id:     "1",
		Name:   "test",
		Client: nil,
		Engine: &ChatEngine{
			Rooms: map[string]*Room{"1": room},
		},
		Rooms: map[string]bool{"1": true},
	}
	// Get the rooms of the user
	rooms := user.GetRooms()
	if len(rooms) != 1 {
		t.Errorf("Expected 1 room, got %d", len(rooms))
	}
}
func Test_UnmarshalJSON(t *testing.T) {
	data := []byte(`{"id": 1, "username": "test"}`)
	user := &User{}
	err := user.UnmarshalJSON(data)
	if err != nil {
		t.Errorf("Unexpected error: %v", err)
	}
	expectedId := "1"
	if user.Id != expectedId {
		t.Errorf("Expected id to be %s, got %s", expectedId, user.Id)
	}
	expectedName := "test"
	if user.Name != expectedName {
		t.Errorf("Expected name to be %s, got %s", expectedName, user.Name)
	}
}
