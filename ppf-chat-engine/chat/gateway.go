package chat

type GatewayManager struct {
	UserGw    UserGateway
	RoomGw    RoomGateway
	MessageGw MessageGateway
}

type Gateway[Pk any, Value any] interface {
	Exists(Pk) bool
	Create(Pk) error
	Read(Pk) Value
	ReadAll() []Value
	Update(Pk, Value) error
	Delete(Pk)

	FindBy(string, any) []Value
}

type IUserGateway interface {
	Gateway[string, User]
}
