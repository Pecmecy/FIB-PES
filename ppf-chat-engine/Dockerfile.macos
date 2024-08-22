FROM golang:1.22-alpine AS builder

RUN apk add gcc
RUN apk add musl-dev

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download
RUN go install github.com/swaggo/swag/cmd/swag@latest

COPY cmd cmd
COPY api api
COPY chat chat

RUN swag init -d cmd,api,chat
RUN CGO_ENABLED=1 GOOS=linux go build -ldflags="-s -w" -o chatengine ./cmd/main.go
RUN ls -la

FROM alpine:3.19

COPY --from=builder /app/chatengine /bin/chatengine

ENTRYPOINT [ "chatengine", "-db", "/opt/chatengine/chat.db" ]