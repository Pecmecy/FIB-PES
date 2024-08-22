package persist

import (
	"log"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// InitDB initializes the database with the specified driver and source.
func Init(source string) *gorm.DB {
	log.Printf("info: init database at %s", source)

	db, err := gorm.Open(sqlite.Open(source), &gorm.Config{})
	if err != nil {
		log.Fatalf("error: failed to connect database")
	}
	db.AutoMigrate(&User{})
	db.AutoMigrate(&Room{})
	db.AutoMigrate(&Message{})
	return db
}
