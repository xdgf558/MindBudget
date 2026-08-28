CREATE TABLE telemetry_identities (
    pseudonymous_id TEXT PRIMARY KEY NOT NULL,
    deletion_handle TEXT NOT NULL,
    expires_at_ms INTEGER NOT NULL,
    CHECK(length(pseudonymous_id) = 36),
    CHECK(length(deletion_handle) = 64)
);

CREATE TRIGGER reject_telemetry_identity_handle_conflict
BEFORE INSERT ON telemetry_identities
WHEN EXISTS (
    SELECT 1
    FROM telemetry_identities
    WHERE pseudonymous_id = NEW.pseudonymous_id
      AND deletion_handle <> NEW.deletion_handle
)
BEGIN
    SELECT RAISE(ABORT, 'telemetry_identity_handle_conflict');
END;

CREATE INDEX idx_telemetry_identities_expiration
    ON telemetry_identities(expires_at_ms);

CREATE TABLE telemetry_events (
    event_id TEXT PRIMARY KEY NOT NULL,
    pseudonymous_id TEXT NOT NULL,
    app_version TEXT NOT NULL,
    occurred_at_ms INTEGER NOT NULL,
    accepted_at_ms INTEGER NOT NULL,
    expires_at_ms INTEGER NOT NULL,
    event_name TEXT NOT NULL,
    action TEXT,
    outcome TEXT,
    event_digest TEXT NOT NULL,
    FOREIGN KEY(pseudonymous_id) REFERENCES telemetry_identities(pseudonymous_id) ON DELETE CASCADE,
    CHECK(length(event_id) = 36),
    CHECK(length(pseudonymous_id) = 36),
    CHECK(length(app_version) BETWEEN 1 AND 32),
    CHECK(length(event_digest) = 64),
    CHECK(event_name IN (
        'app_session_started',
        'pro_surface',
        'subscription_action',
        'receipt_flow',
        'cloud_sync_control'
    )),
    CHECK(outcome IS NULL OR outcome IN ('completed', 'cancelled', 'unavailable', 'failed'))
);

CREATE TRIGGER reject_telemetry_event_id_conflict
BEFORE INSERT ON telemetry_events
WHEN EXISTS (
    SELECT 1
    FROM telemetry_events
    WHERE event_id = NEW.event_id
      AND event_digest <> NEW.event_digest
)
BEGIN
    SELECT RAISE(ABORT, 'telemetry_event_id_conflict');
END;

CREATE INDEX idx_telemetry_events_identity
    ON telemetry_events(pseudonymous_id);
CREATE INDEX idx_telemetry_events_expiration
    ON telemetry_events(expires_at_ms);

CREATE TABLE telemetry_deleted_identities (
    pseudonymous_id TEXT NOT NULL,
    deletion_handle TEXT NOT NULL,
    expires_at_ms INTEGER NOT NULL,
    PRIMARY KEY(pseudonymous_id, deletion_handle),
    CHECK(length(pseudonymous_id) = 36),
    CHECK(length(deletion_handle) = 64)
);

CREATE INDEX idx_telemetry_deleted_expiration
    ON telemetry_deleted_identities(expires_at_ms);
