package reservation

import (
	"context"
	"fmt"
	"math/big"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

type Service struct {
	rdb *redis.Client
}

func New(addr string) *Service {
	return &Service{rdb: redis.NewClient(&redis.Options{Addr: addr})}
}

func NewWithClient(rdb *redis.Client) *Service {
	return &Service{rdb: rdb}
}

func (s *Service) Ping(ctx context.Context) error {
	return s.rdb.Ping(ctx).Err()
}

func idemKey(sessionID, idempotencyKey string) (string, error) {
	idempotencyKey = strings.TrimSpace(idempotencyKey)
	sessionID = strings.TrimSpace(sessionID)
	if idempotencyKey == "" {
		return "", fmt.Errorf("idempotencyKey required")
	}
	if sessionID == "" {
		return "", fmt.Errorf("sessionId required")
	}
	return fmt.Sprintf("idem:%s:%s", sessionID, idempotencyKey), nil
}

func sessionKey(sessionID string) string {
	return "reserve:" + sessionID
}

func lockKey(sessionID string) string {
	return "reserve-lock:" + sessionID
}

func reservationMetaKey(reservationID string) string {
	return "resmeta:" + reservationID
}

// Reserve atomically checks session budget using string big-int math in Go (safe above 2^53).
func (s *Service) Reserve(ctx context.Context, sessionID, idempotencyKey, amountAtomic, maxTotalSpend string, preSubmitTTL time.Duration) (string, error) {
	idem, err := idemKey(sessionID, idempotencyKey)
	if err != nil {
		return "", err
	}
	amount, ok := new(big.Int).SetString(amountAtomic, 10)
	if !ok || amount.Sign() <= 0 {
		return "", fmt.Errorf("invalid amountAtomic")
	}
	maxTotal, ok := new(big.Int).SetString(maxTotalSpend, 10)
	if !ok || maxTotal.Sign() <= 0 {
		return "", fmt.Errorf("invalid maxTotalSpend")
	}

	if existing, err := s.rdb.Get(ctx, idem).Result(); err == nil && existing != "" {
		return existing, nil
	}

	lock := lockKey(sessionID)
	acquired, err := s.rdb.SetNX(ctx, lock, "1", 10*time.Second).Result()
	if err != nil {
		return "", err
	}
	if !acquired {
		return "", fmt.Errorf("BUDGET_BUSY")
	}
	defer s.rdb.Del(ctx, lock)

	currentStr, err := s.rdb.Get(ctx, sessionKey(sessionID)).Result()
	if err == redis.Nil {
		currentStr = "0"
	} else if err != nil {
		return "", err
	}
	current, ok := new(big.Int).SetString(currentStr, 10)
	if !ok {
		current = big.NewInt(0)
	}
	next := new(big.Int).Add(current, amount)
	if next.Cmp(maxTotal) > 0 {
		return "", fmt.Errorf("BUDGET_DENIED")
	}

	reservationID := "res_" + uuid.NewString()
	ttlSec := int(preSubmitTTL.Seconds())
	if ttlSec <= 0 {
		ttlSec = 300
	}

	pipe := s.rdb.TxPipeline()
	pipe.Set(ctx, sessionKey(sessionID), next.String(), 0)
	pipe.Set(ctx, idem, reservationID, time.Duration(ttlSec)*time.Second)
	pipe.Set(ctx, reservationMetaKey(reservationID), sessionID+"|"+amountAtomic, time.Duration(ttlSec)*time.Second)
	if _, err := pipe.Exec(ctx); err != nil {
		return "", err
	}
	return reservationID, nil
}

func (s *Service) CommitReservation(ctx context.Context, reservationID string) error {
	return s.rdb.Del(ctx, reservationMetaKey(reservationID)).Err()
}

func (s *Service) ReleaseReservation(ctx context.Context, reservationID string) error {
	meta, err := s.rdb.Get(ctx, reservationMetaKey(reservationID)).Result()
	if err == redis.Nil {
		return nil
	}
	if err != nil {
		return err
	}
	parts := strings.SplitN(meta, "|", 2)
	if len(parts) != 2 {
		return fmt.Errorf("invalid reservation metadata")
	}
	sessionID, amountAtomic := parts[0], parts[1]
	amount, ok := new(big.Int).SetString(amountAtomic, 10)
	if !ok {
		return fmt.Errorf("invalid reserved amount")
	}

	lock := lockKey(sessionID)
	acquired, err := s.rdb.SetNX(ctx, lock, "1", 10*time.Second).Result()
	if err != nil {
		return err
	}
	if !acquired {
		return fmt.Errorf("BUDGET_BUSY")
	}
	defer s.rdb.Del(ctx, lock)

	currentStr, err := s.rdb.Get(ctx, sessionKey(sessionID)).Result()
	if err == redis.Nil {
		return s.rdb.Del(ctx, reservationMetaKey(reservationID)).Err()
	}
	if err != nil {
		return err
	}
	current, ok := new(big.Int).SetString(currentStr, 10)
	if !ok {
		return fmt.Errorf("invalid session reserve state")
	}
	next := new(big.Int).Sub(current, amount)
	if next.Sign() < 0 {
		next = big.NewInt(0)
	}
	pipe := s.rdb.TxPipeline()
	pipe.Set(ctx, sessionKey(sessionID), next.String(), 0)
	pipe.Del(ctx, reservationMetaKey(reservationID))
	_, err = pipe.Exec(ctx)
	return err
}
