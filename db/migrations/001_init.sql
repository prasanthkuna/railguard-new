CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY,
    session_id TEXT UNIQUE NOT NULL,
    account TEXT NOT NULL,
    agent_id TEXT NOT NULL,
    session_key TEXT NOT NULL,
    token TEXT NOT NULL,
    allowed_target TEXT NOT NULL,
    allowed_recipient TEXT NOT NULL,
    allowed_selector TEXT NOT NULL,
    nonce_key TEXT NOT NULL,
    max_per_transfer NUMERIC(78,0) NOT NULL,
    max_total_spend NUMERIC(78,0) NOT NULL,
    valid_after BIGINT NOT NULL,
    valid_until BIGINT NOT NULL,
    allow_batch BOOLEAN NOT NULL DEFAULT false,
    policy_hash TEXT NOT NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at TIMESTAMPTZ,
    UNIQUE (account, nonce_key)
);

CREATE TABLE IF NOT EXISTS payment_intents (
    id UUID PRIMARY KEY,
    intent_hash TEXT UNIQUE NOT NULL,
    agent_id TEXT NOT NULL,
    account TEXT NOT NULL,
    chain_id BIGINT NOT NULL,
    token TEXT NOT NULL,
    recipient TEXT NOT NULL,
    amount_atomic NUMERIC(78,0) NOT NULL,
    resource_domain TEXT,
    resource_path TEXT,
    idempotency_key TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS policy_decisions (
    id UUID PRIMARY KEY,
    decision_id TEXT UNIQUE NOT NULL,
    intent_hash TEXT NOT NULL,
    decision TEXT NOT NULL CHECK (decision IN ('ALLOW', 'BLOCK')),
    reason_codes JSONB NOT NULL,
    policy_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS budget_reservations (
    id UUID PRIMARY KEY,
    reservation_id TEXT UNIQUE NOT NULL,
    session_id TEXT NOT NULL,
    intent_hash TEXT NOT NULL,
    agent_id TEXT NOT NULL,
    amount_atomic NUMERIC(78,0) NOT NULL,
    status TEXT NOT NULL,
    idempotency_key TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    submitted_at TIMESTAMPTZ,
    finalized_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS userop_lifecycle (
    id UUID PRIMARY KEY,
    userop_hash TEXT UNIQUE NOT NULL,
    reservation_id TEXT NOT NULL,
    session_id TEXT NOT NULL,
    status TEXT NOT NULL,
    bundler TEXT,
    tx_hash TEXT,
    block_number BIGINT,
    submitted_at TIMESTAMPTZ,
    included_at TIMESTAMPTZ,
    finalized_at TIMESTAMPTZ,
    last_checked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS audit_receipts (
    id UUID PRIMARY KEY,
    decision_id TEXT UNIQUE NOT NULL,
    intent_hash TEXT NOT NULL,
    session_id TEXT,
    receipt_hash TEXT NOT NULL,
    receipt_json JSONB NOT NULL,
    signature TEXT NOT NULL,
    signer_key_id TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
