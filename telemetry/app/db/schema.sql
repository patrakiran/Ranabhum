CREATE EXTENSION IF NOT EXISTS timescaledb;

CREATE TABLE IF NOT EXISTS order_metrics (
    submission_id   TEXT NOT NULL,
    run_id          TEXT NOT NULL,
    order_id        TEXT NOT NULL,
    order_type      TEXT NOT NULL,
    sent_at         TIMESTAMPTZ NOT NULL,
    latency_ns      BIGINT NOT NULL,
    fill_correct    INTEGER NOT NULL,
    bot_id          TEXT NOT NULL,
    side            TEXT,
    price           NUMERIC,
    quantity        INTEGER,
    ack_at_ns       BIGINT,
    expected_fill_qty  INTEGER,
    actual_fill_qty INTEGER,
    expected_fill_price NUMERIC,
    actual_fill_price NUMERIC,
    status          TEXT,
    reject_reason   TEXT,
    cancel_order_id TEXT,

    UNIQUE (run_id, order_id, sent_at)
);


SELECT create_hypertable(
    'order_metrics', 'sent_at',
    chunk_time_interval => INTERVAL '1 hour',
    if_not_exists => TRUE
);

ALTER TABLE order_metrics SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'run_id'
);

--  Compression policy: auto-compress any chunk older than 1 hour.
SELECT add_compression_policy('order_metrics', INTERVAL '1 hour', if_not_exists => TRUE);

-- Retention policy: auto-DROP chunks older than 7 days so the table

SELECT add_retention_policy('order_metrics', INTERVAL '7 days', if_not_exists => TRUE);

CREATE INDEX IF NOT EXISTS idx_submission_run
ON order_metrics (submission_id, run_id, sent_at DESC);