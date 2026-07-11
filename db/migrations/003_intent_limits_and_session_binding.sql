ALTER TABLE payment_intents
  ADD COLUMN IF NOT EXISTS max_per_transfer NUMERIC(78, 0),
  ADD COLUMN IF NOT EXISTS max_total_spend NUMERIC(78, 0),
  ADD COLUMN IF NOT EXISTS allow_batch BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE policy_decisions
  ADD COLUMN IF NOT EXISTS consumed_session_id TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS policy_decisions_consumed_session_idx
  ON policy_decisions (consumed_session_id)
  WHERE consumed_session_id IS NOT NULL;
