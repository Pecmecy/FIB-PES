package test

import (
	"errors"
	"log"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strings"
	"testing"

	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	"github.com/pes2324q2-gei-upc/ppf-chat-engine/api"
	"github.com/pes2324q2-gei-upc/ppf-chat-engine/auth"
	"github.com/pes2324q2-gei-upc/ppf-chat-engine/chat"
	"github.com/pes2324q2-gei-upc/ppf-chat-engine/config"
	"github.com/pes2324q2-gei-upc/ppf-chat-engine/persist"
	"gorm.io/gorm"
)

func NewTestChatEngine(db *gorm.DB) (*chat.ChatEngine, error) {
	useUrl, _ := url.Parse(config.GetEnv("USER_API_URL", "http://localhost:8081"))
	routeUrl, _ := url.Parse(config.GetEnv("ROUTE_API_URL", "http://localhost:8080"))

	credentials := &auth.UserApiCredentials{
		AuthUrl:  useUrl.JoinPath("login"),
		Email:    config.GetEnv("PPF_MAIL", "admin@ppf.com"),
		Password: config.GetEnv("PPF_PASS", "chatengine"),
	}
	configuration := config.Configuration{
		Debug:       config.GetEnv("DEBUG", "false") == "true",
		UserApiUrl:  *useUrl,
		RouteApiUrl: *routeUrl,
		Credentials: credentials,
	}
	gwm := chat.GatewayManager{
		UserGw: chat.UserGateway{
			Repo: persist.UserRepository{Db: db},
		},
		RoomGw: chat.RoomGateway{
			Repo: persist.RoomRepository{Db: db},
		},
		MessageGw: chat.MessageGateway{
			Repo: persist.MessageRepository{Db: db},
		},
	}
	engine := &chat.ChatEngine{
		Configuration:  configuration,
		HttpClient:     http.DefaultClient,
		Server:         nil,
		GatewayManager: gwm,
		Users:          make(map[string]*chat.User),
		Rooms:          make(map[string]*chat.Room),
	}
	wsserver := chat.NewWsServer(engine)
	wsserver.Engine = engine
	engine.Server = wsserver
	return engine, nil
}

var (
	engine     *chat.ChatEngine
	mockServer *httptest.Server
	database   *gorm.DB

	testUser1 *chat.User
	testUser2 *chat.User
	testRoom1 *chat.Room
	testRoom2 *chat.Room
)

func setup() {
	log.Default().Println("Setting up test environment")

	testUser1 = chat.NewUser("user1", "User 1", nil)
	testUser2 = chat.NewUser("user2", "User 2", nil)
	testRoom1 = chat.NewRoom("room1", "Room 1", &testUser1.Name)
	testRoom2 = chat.NewRoom("room2", "Room 2", &testUser2.Name)

	mockServer = httptest.NewUnstartedServer(nil)

	database = persist.Init("file::memory:?cache=shared")

	engine, _ = NewTestChatEngine(database)
	ctrl := api.NewChatController(mux.NewRouter(), engine)
	mockServer.Config.Handler = ctrl.Router
}

func teardown() {
	d, _ := database.DB()
	d.Close()
	mockServer.Close()
	engine = nil
}

func TestMain(m *testing.M) {
	setup()
	code := m.Run()
	teardown()
	os.Exit(code)
}

func Test_ConnectUser(t *testing.T) {
	// Create a test server with the WebSocket handler
	s := httptest.NewServer(http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			err := engine.ConnectUser(testUser1.Id, w, r)
			if errors.Is(err, chat.ErrUserNotFound) {
				w.WriteHeader(http.StatusNotFound)
			}
		}))
	defer s.Close()

	// Create a WebSocket connection to the test server
	connect := func() (*websocket.Conn, *http.Response, error) {
		// Convert the HTTP URL to a WebSocket URL
		wsURL := "ws" + strings.TrimPrefix(s.URL, "http") + "/connect/-"
		// Dial the WebSocket
		c, r, err := websocket.DefaultDialer.Dial(wsURL, nil)
		return c, r, err
	}

	// Test case for when a user is loaded into the engine
	t.Run("User loaded", func(t *testing.T) {
		engine.Users[testUser1.Id] = testUser1
		defer delete(engine.Users, testUser1.Id)

		con, resp, err := connect()
		if err != nil {
			t.Fatal(err)
		}
		defer con.Close()
		// Check response status code
		if resp.StatusCode != http.StatusSwitchingProtocols {
			t.Errorf("Expected status code %d, got %d", http.StatusOK, resp.StatusCode)
		}
	})

	// Test case for when the user is not loaded into the engine
	t.Run("User not loaded", func(t *testing.T) {
		con, resp, err := connect()
		if con != nil {
			con.Close()
			t.Errorf("Expected connection to be nil, got %v", con)
		}
		if !errors.Is(err, websocket.ErrBadHandshake) {
			t.Errorf("Expected error %v, got %v", websocket.ErrBadHandshake, err)
		}
		if resp.StatusCode != http.StatusNotFound {
			t.Errorf("Expected status code %d, got %d", http.StatusNotFound, resp.StatusCode)
		}
	})
}

// // // setupRoom1 sets up the test room 1 and returns a teardown function
// // func setupRoom1() func() {
// // 	engine.Users[testUser1.Id] = testUser1 // Añade cosas a un map
// // 	engine.Rooms[testRoom1.Id] = testRoom1
// // 	go testRoom1.Run() // Inicia una corutina
// // 	return func() {    // Devuelve una función que borra lo que se ha añadido
// // 		delete(engine.Users, testUser1.Id) // Y para la corutina
// // 		delete(engine.Rooms, testRoom1.Id)
// // 		testRoom1.Close()
// // 	}
// // }
// // func Test_JoinRoom(t *testing.T) {
// // 	teardownRoom1 := setupRoom1()
// // 	defer teardownRoom1() // Defer hace que se ejecute al final de la función

// // 	// Test case for joining an existing room
// // 	t.Run("Join existing room", func(t *testing.T) {
// // 		err := engine.JoinRoom(testRoom1.Id, testUser1.Id)
// // 		<-time.After(time.Millisecond) // Need to wait for the room to process the join request
// // 		if err != nil {
// // 			t.Errorf("Expected no error, got %v", err)
// // 		}
// // 		if _, ok := testRoom1.Users[testUser1.Id]; !ok {
// // 			t.Errorf("User not found in room")
// // 		}
// // 	})
// // 	// Test case for joining a non-existing room
// // 	t.Run("Join non-existing room", func(t *testing.T) {
// // 		if err := engine.JoinRoom("nonExistingRoom", testUser1.Id); !errors.Is(err, ErrRoomNotFound) {
// // 			t.Errorf("Expected error %v, got %v", ErrRoomNotFound, err)
// // 		}
// // 	})
// // 	// Test case for joining a room with a non-existing user
// // 	t.Run("Join room with non-existing user", func(t *testing.T) {
// // 		if err := engine.JoinRoom(testRoom1.Id, "nonExistingUser"); !errors.Is(err, ErrUserNotFound) {
// // 			t.Errorf("Expected error %v, got %v", ErrUserNotFound, err)
// // 		}
// // 	})
// // }

// // func Test_LeaveRoom(t *testing.T) {
// // 	teardownRoom1 := setupRoom1()
// // 	defer teardownRoom1()
// // 	// Test case for leaving an existing room
// // 	t.Run("Leave existing room", func(t *testing.T) {
// // 		defer func() { // Restore test case changes
// // 			engine.Users[testUser1.Id] = testUser1
// // 		}()
// // 		err := engine.LeaveRoom(testRoom1.Id, testUser1.Id)
// // 		<-time.After(time.Millisecond) // Need to wait for the room to process the leave request
// // 		if err != nil {
// // 			t.Errorf("Expected no error, got %v", err)
// // 		}
// // 		if _, ok := testRoom1.Users[testUser1.Id]; ok {
// // 			t.Errorf("User still found in room")
// // 		}
// // 	})
// // 	// Test case for leaving a non-existing room
// // 	t.Run("Leave non-existing room", func(t *testing.T) {
// // 		err := engine.LeaveRoom("nonExistingRoom", testUser1.Id)
// // 		if !errors.Is(err, ErrRoomNotFound) {
// // 			t.Errorf("Expected error %v, got %v", ErrRoomNotFound, err)
// // 		}
// // 	})
// // 	// Test case for leaving a room with a non-existing user
// // 	t.Run("Leave room with non-existing user", func(t *testing.T) {
// // 		err := engine.LeaveRoom(testRoom1.Id, "nonExistingUser")
// // 		if !errors.Is(err, ErrUserNotFound) {
// // 			t.Errorf("Expected error %v, got %v", ErrUserNotFound, err)
// // 		}
// // 	})
// // }

// // func Test_Exists(t *testing.T) {
// // 	engine.Users[testUser1.Id] = testUser1
// // 	defer delete(engine.Users, testUser1.Id)
// // 	// Test case for an existing user
// // 	t.Run("Existing user", func(t *testing.T) {
// // 		// Check if the user exists
// // 		if exists := engine.Exists(testUser1.Id); !exists {
// // 			t.Errorf("Expected user to exist, but it doesn't")
// // 		}
// // 	})
// // 	// Test case for a non-existing user
// // 	t.Run("Non-existing user", func(t *testing.T) {
// // 		// Check if a non-existing user exists
// // 		exists := engine.Exists("nonExistingUser")
// // 		if exists {
// // 			t.Errorf("Expected user to not exist, but it does")
// // 		}
// // 	})
// // }
// // func Test_OpenRoom(t *testing.T) {
// // 	engine.Users[testUser1.Id] = testUser1
// // 	defer delete(engine.Users, testUser1.Id)

// // 	// Test case for opening a room with an existing driver
// // 	t.Run("Open room with loaded driver", func(t *testing.T) {
// // 		var room *Room
// // 		roomID := "room1"
// // 		roomName := "Room 1"
// // 		t.Run("Success", func(t *testing.T) {
// // 			if err := engine.OpenRoom(roomID, roomName, testUser1.Id); err != nil {
// // 				t.Errorf("Expected no error, got %v", err)
// // 			}
// // 		})
// // 		t.Run("Room added", func(t *testing.T) {
// // 			// Check if the room is added to the engine
// // 			var ok bool
// // 			if room, ok = engine.Rooms[roomID]; !ok {
// // 				t.Errorf("Expected room to be added to the engine")
// // 			}
// // 		})
// // 		t.Run("Correct driver", func(t *testing.T) {
// // 			// Check if the room's driver is set correctly
// // 			if *room.Driver != testUser1.Id {
// // 				t.Errorf("Expected room's driver to be %s, got %s", testUser1.Id, *room.Driver)
// // 			}
// // 		})
// // 	})

// // 	// Test case for opening a room with a non-existing driver
// // 	t.Run("Open room with non-existing driver", func(t *testing.T) {
// // 		roomID := "room2"
// // 		roomName := "Room 2"
// // 		nonExistingDriverID := "nonExistingDriver"

// // 		err := engine.OpenRoom(roomID, roomName, nonExistingDriverID)
// // 		if !errors.Is(err, ErrUserNotFound) {
// // 			t.Errorf("Expected error %v, got %v", ErrUserNotFound, err)
// // 		}

// // 		// Check if the room is not added to the engine
// // 		_, ok := engine.Rooms[roomID]
// // 		if ok {
// // 			t.Errorf("Expected room to not be added to the engine")
// // 		}
// // 	})
// // }
