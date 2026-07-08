CREATE TABLE IF NOT EXISTS watcher_state (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS chain_executions (
    id UUID PRIMARY KEY,
    account TEXT NOT NULL,
    session_id TEXT NOT NULL,
    nonce_key TEXT NOT NULL,
    frame_spend NUMERIC(78,0) NOT NULL,
    total_spend_after NUMERIC(78,0) NOT NULL,
    block_number BIGINT NOT NULL,
    tx_hash TEXT NOT NULL,
    log_index INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tx_hash, log_index)
);
