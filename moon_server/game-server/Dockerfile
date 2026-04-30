# ─── Build stage ────────────────────────────────────────────────────────────
FROM golang:1.22-alpine AS builder

WORKDIR /build
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
RUN go build -o moon-game-server ./main.go

# ─── Runtime stage ───────────────────────────────────────────────────────────
FROM alpine:3.19
WORKDIR /app

COPY --from=builder /build/moon-game-server .

ENV PORT=8080
EXPOSE 8080

CMD ["./moon-game-server"]
