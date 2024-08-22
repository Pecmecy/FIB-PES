package persist

import (
	"errors"

	"gorm.io/gorm"
)

type User struct {
	Id   string `gorm:"primarykey"`
	Name string
}

func (r User) Pk() string { return r.Id }

type UserRepository struct {
	Db *gorm.DB
}

func (repo *UserRepository) Exists(id string) bool {
	r := repo.Db.First(&User{})
	if r.Error != nil {
		return false
	}
	return r.RowsAffected >= 1
}

func (repo UserRepository) Create(user User) error {
	return repo.Db.Create(&user).Error
}

func (repo UserRepository) Read(id string) *User {
	var result *User = &User{Id: id}
	repo.Db.First(result).Preload("Rooms")
	return result
}

func (repo UserRepository) ReadAll() []*User {
	var users []*User = make([]*User, 0)
	repo.Db.Find(users)
	return users
}

func (repo UserRepository) Update(id string, user *User) error {
	return nil
}

func (repo UserRepository) Delete(id string) {
	repo.Db.Delete(&User{}, id)
}

func (repo UserRepository) AddRoom(user User, room Room) error {
	stm := repo.Db.Model(&user).Association("Rooms").Append(&room)
	return errors.New(stm.Error())
}

func (repo UserRepository) RemoveRoom(user User, room Room) error {
	stm := repo.Db.Model(&user).Association("Rooms").Delete(&room)
	return errors.New(stm.Error())
}
