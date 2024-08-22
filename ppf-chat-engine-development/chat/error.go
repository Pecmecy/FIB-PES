package chat

import "errors"

var (
	ErrUserNotFound         = errors.New("user not loaded")
	ErrUserUnmarshalFailed  = errors.New("user could not be parsed")
	ErrRoomNotFound         = errors.New("room not loaded")
	ErrUserApiRequestFailed = errors.New("user api request failed")
	ErrRouteUnmarshalFailed = errors.New("route could not be parsed")
	ErrNoMessageId          = errors.New("message id is missing")
	ErrWrongMessageSender   = errors.New("wrong message sender")
)
