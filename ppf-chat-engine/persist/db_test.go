package persist

import (
	"os"
	"testing"

	"gorm.io/gorm"
)

func TestInitDB(t *testing.T) {
	// Create a temporary database file
	tempDBFile := "file::memory:?cache=shared"
	defer os.Remove(tempDBFile)

	// Call the InitDB function
	var db *gorm.DB = Init(tempDBFile)

	// Check if the User table is created
	if !db.Migrator().HasTable(&User{}) {
		t.Errorf("User table was not created")
	}

	// Check if the Room table is created
	if !db.Migrator().HasTable(&Room{}) {
		t.Errorf("Room table was not created")
	}

	// Check if the Message table is created
	if !db.Migrator().HasTable(&Message{}) {
		t.Errorf("Message table was not created")
	}
}
