# Chat Engine Design
> Design document for the Chat Engine, contains sequence diagrams, design decisions, etc

- [Chat Engine Design](#chat-engine-design)
  - [Sequence Diagrams](#sequence-diagrams)
    - [**Chat Engine start**](#chat-engine-start)
    - [**Driver creates route**](#driver-creates-route)
    - [**User joins route**](#user-joins-route)
    - [**User leaves route**](#user-leaves-route)
    - [**User connects**](#user-connects)
    - [**User disconnects**](#user-disconnects)
    - [**User sends message**](#user-sends-message)
      - [**User requests joined rooms**](#user-requests-joined-rooms)
      - [**User requests room messages**](#user-requests-room-messages)
      - [**User sends text message**](#user-sends-text-message)
  - [Messages](#messages)
    - [Message schema](#message-schema)
    - [Error messages](#error-messages)
  - [PlantUML](#plantuml)
  - [Design Decisions](#design-decisions)
    - [DD1](#dd1)


**Abreviations:**
- `Chat Engine : CE`

## Sequence Diagrams
### TBD

## Messages
### Message schema
> Both client to server and server to client follow the same schema.

```json
{
    "messageId": "string",
    "command": "string",
    "content": "string",
    "room": "string",
    "sender": "string"
}
```
- `messageId`: unique identifier for the message, the client is responsible for generating this. If it's not unique it may cause undefined behavior.
- `command`: the command to execute.
- `content`: the content of the message.
- `room`: the room the message is related to.
- `sender`: the user that sent the message, it must match the one used in the WebSocket connection, otherwise the message will be ignored.

Fields of the CE response will match the ones from the 'request', only the content field will contain the response data which will consist of a json encoded string.
Use this documentation to know the structure of the content field.

**Get joined rooms**  
_Message:_
```json
// Message
{
    "messageId": "<msg_id>",
    "command": "GetRooms",
    "content": "", // ignored
    "room": "", // ignored
    "sender": "<user_id>"
}
```
_Response:_
```json
{
    ···
    "content": {
        "status": "ok",
        "rooms": [
            {
                "id": "<room_id>",
                "name": "<room_name>",
                "driver": {
                    "id": "<user_id>",
                    "name": "<user_name>"
                },
                "users": [
                    {
                        "id": "<user_id>",
                        "name": "<user_name>"
                    },
                    ...
                ]
            },
            ...
        ]
    }
    ···
}
```

**Get room messages**
_Message:_
```json
{
    "messageId": "<msg_id>",
    "command": "GetRoomMessages",
    "content": "",
    "room": "<room_id>",
    "sender": "<user_id>"
}
```

_Response:_
```json
{
    ···
    "content": {
        "status": "ok",
        "messages": [
            {
                "ts": "<datetime RFC3339>" // 2006-01-02T15:04:05Z07:00
                "content": "<message>",
                "room": "<room_id>",
                "sender": {
                    "id": "<user_id>",
                    "username": "<user_name>",
                },
            },
            ...
        ]
    }
    ···
}
```

**Send message**
```json
{
    "messageId": "<msg_id>",
    "command": "SendMessage",
    "content": "<message>",
    "room": "<room_id>",
    "sender": "<user_id>"
}
```
```json
{
    ···
    "content": {"status":"ok", "message":"sent"}
    ···
}
```

### Error messages  
An error will have the following structure:
```json
{
    "content": {
        "status": "error",
        "error": "<error_message>"
    }
}
```

**Error messages**
| error                    | description                                               |
| ------------------------ | --------------------------------------------------------- |
| `"message is malformed"` | The message does not follow the expected schema           |
| `"no message id"`        | The message does not follow the expected schema           |
| `"command not found"`    | The provided command does not exist                       |
| `"wrong message sender"` | The provided sender does not match the expected user id   |
| `"room not found"`       | The user does not belong to any room with the provided id |
| `"not implemented"`      | The command is valid but not implemented yet              |

## PlantUML
![Architecture](ChatEngineMain.png)

## Design Decisions
### DD1
Every time the CE starts it requests all routes and users. While this is not the most efficient way to handle this, it is the simplest way to ensure that the CE has all the data it needs to function. **A trade-off between performance and simplicity.** The CE could be optimized to only request the routes and users that have changed since the last time it started or queue room creation at the RouteAPI.




