FROM golang:1.22-alpine AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /signgate ./cmd/api

FROM alpine:3.20
WORKDIR /app
COPY --from=build /signgate /app/signgate
EXPOSE 8080
CMD ["/app/signgate"]
