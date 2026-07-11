ALTER TABLE chain_executions
  ADD COLUMN IF NOT EXISTS execution_digest TEXT;

ALTER TABLE budget_reservations
  ADD COLUMN IF NOT EXISTS execution_digest TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS chain_executions_execution_digest_idx
  ON chain_executions (execution_digest)
  WHERE execution_digest IS NOT NULL;

CREATE INDEX IF NOT EXISTS budget_reservations_execution_digest_idx
  ON budget_reservations (execution_digest)
  WHERE execution_digest IS NOT NULL;
