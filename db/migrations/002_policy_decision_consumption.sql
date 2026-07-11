ALTER TABLE policy_decisions
  ADD COLUMN IF NOT EXISTS consumed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS consumed_session_id TEXT;
