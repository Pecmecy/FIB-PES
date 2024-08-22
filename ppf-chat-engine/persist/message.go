package persist

import (
	"errors"
	"fmt"
	"time"

	"log"

	"gorm.io/gorm"
)

// The primary
type MessageKey struct {
	room   string
	sender string
}

func (k MessageKey) Pk() (string, string) { return k.room, k.sender }

func MakeMessageKey(room string, sender string) MessageKey {
	return MessageKey{
		room,
		sender,
	}
}

type Message struct {
	Id        uint
	CreatedAt time.Time

	RoomID   string `gorm:"type:varchar(255)"` // Foreign key for Room
	Room     Room   `gorm:"foreignKey:RoomID"`
	SenderID string `gorm:"type:varchar(255)"` // Foreign key for User
	Sender   User   `gorm:"foreignKey:SenderID"`
	Content  string
}

func (r Message) Pk() MessageKey {
	return MessageKey{
		room:   r.Room.Pk(),
		sender: r.Sender.Pk(),
	}
}

type MessageRepository struct {
	Db *gorm.DB
}

func (repo MessageRepository) Exists(pk MessageKey) bool {
	r := repo.Db.First(&Message{}).Where("room_id = ? AND sender_id = ?", pk.room, pk.sender)
	if r.Error != nil {
		if errors.Is(r.Error, gorm.ErrRecordNotFound) {
			return false
		}
		log.Print(fmt.Errorf("message repo error: %w", r.Error))
		return false
	}
	return true
}

func (repo MessageRepository) Create(msg Message) error {
	return repo.Db.Create(&msg).Error
}

func (repo MessageRepository) Read(pk MessageKey) Message {
	result := Message{}
	repo.Db.First(result).Where("room_id = ? AND sender_id = ?", pk.room, pk.sender)
	return result
}

func (repo MessageRepository) ReadAll() []Message {
	var results []Message = make([]Message, 0)
	repo.Db.Preload("Room").Preload("Sender").Find(results)
	return results
}

func (repo MessageRepository) Update(pk MessageKey, msg Message) error {
	return nil
}

func (repo MessageRepository) Delete(pk MessageKey) {
	repo.Db.Delete(&Message{}).Where("room_id = ? AND sender_id = ?", pk.room, pk.sender)

}

func (repo MessageRepository) GetByRoom(room Room) ([]Message, error) {
	var results []Message
	err := repo.Db.Where(Message{RoomID: room.Id}).Find(&results).Preload("Sender").Error
	return results, err
}

func (repo MessageRepository) GetBySender(sender User) ([]Message, error) {
	var results []Message
	err := repo.Db.Where(&Message{Sender: sender}).Preload("Room").Find(&results).Error
	return results, err
}
