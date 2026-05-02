package main

import (
	"errors"
	"math"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type Claims struct {
	UserID    string `json:"user_id"`
	Username  string `json:"username"`
	RoleLevel int    `json:"role_level"`
	ClassID   string `json:"class_id"`
	jwt.RegisteredClaims
}

func validateJWT(tokenStr string) (*Claims, error) {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		return nil, errors.New("JWT_SECRET not configured")
	}
	claims := &Claims{}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (any, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(secret), nil
	})
	if err != nil || !token.Valid {
		return nil, errors.New("invalid token")
	}
	return claims, nil
}

func validateInput(p *Player, input *PlayerInput) error {
	if input.Seq <= p.LastSeqSeen && p.LastSeqSeen > 0 {
		return errors.New("duplicate or replayed seq")
	}

	mag := math.Sqrt(input.MoveX*input.MoveX + input.MoveY*input.MoveY)
	if mag > 1.0+0.01 {
		return errors.New("move vector too large (speed hack)")
	}

	if math.IsNaN(input.Rotation) || math.IsInf(input.Rotation, 0) {
		return errors.New("invalid rotation value")
	}

	if input.AttackFlags < 0 || input.AttackFlags > 0xFF {
		return errors.New("invalid attack flags")
	}

	return nil
}

func validateAttack(p *Player) bool {
	return time.Since(p.LastAttackTime).Milliseconds() >= AttackCooldownMs
}
