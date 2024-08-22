package persist

import (
	"gorm.io/gorm"
)

type Room struct {
	Id     string `gorm:"primarykey"`
	Name   string
	Driver string
	Users  []*User `gorm:"many2many:users_rooms;"`
}

func (r Room) Pk() string { return r.Id }

type RoomRepository struct {
	Db *gorm.DB
}

func (repo RoomRepository) Exists(pk string) bool {
	r := repo.Db.First(&Room{Id: pk})
	if r.Error != nil {
		return false
	}
	return r.RowsAffected >= 1
}

func (repo RoomRepository) Create(room Room) error {
	return repo.Db.Create(&room).Error
}

func (repo RoomRepository) Read(id string) *Room {
	var result *Room = &Room{Id: id}
	repo.Db.First(result)
	return result
}

func (repo RoomRepository) ReadAll() []*Room {
	var results []*Room = make([]*Room, 0)
	repo.Db.Find(results)
	return results
}

func (repo RoomRepository) Update(id string, room *Room) error {
	return nil
}

func (repo RoomRepository) Delete(id string) {
	repo.Db.Delete(&Room{Id: id})
}

func (repo RoomRepository) AddUser(room Room, user User) error {
	return repo.Db.Model(&room).Association("Users").Append(&user)
}

func (repo RoomRepository) RemoveUser(room Room, user User) error {
	return repo.Db.Model(&room).Association("Users").Delete(&user)
}
