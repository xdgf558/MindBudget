const EVENTS_PATH = "/v1/events";
const DELETE_PATH = "/v1/delete";
const MAXIMUM_UPLOAD_BYTES = 32 * 1024;
const MAXIMUM_DELETE_BYTES = 2 * 1024;
const MAXIMUM_BATCH_EVENTS = 20;
const MAXIMUM_DELETE_PROOFS = 4;
const RETENTION_MILLISECONDS = 90 * 24 * 60 * 60 * 1000;
const UTC_DAY_MILLISECONDS = 24 * 60 * 60 * 1000;
const MAXIMUM_FUTURE_SKEW_MILLISECONDS = 10 * 60 * 1000;
const CLEANUP_BATCH_SIZE = 1_000;
const FIXED_USER_AGENT = "MindBudget";
const UUID_V4_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const LOWER_HEX_32_PATTERN = /^[0-9a-f]{64}$/;
const APP_VERSION_PATTERN = /^[0-9]+(?:\.[0-9]+)*$/;
const BASE64_32_PATTERN = /^[A-Za-z0-9+/]{43}=$/;

type WorkerEnvironment = Pick<
  Env,
  | "DEPLOYMENT_ENVIRONMENT"
  | "EXPECTED_HOST"
  | "TELEMETRY_DB"
  | "TELEMETRY_EDGE_RATE_LIMITER"
  | "TELEMETRY_IDENTITY_RATE_LIMITER"
>;

type JSONValue = null | boolean | number | string | JSONValue[] | JSONObject;
type JSONObject = { [key: string]: JSONValue };

type AcceptedEnvironment = "development" | "staging" | "production";
type AcceptedOutcome = "completed" | "cancelled" | "unavailable" | "failed";
type AcceptedEventName =
  | "app_session_started"
  | "pro_surface"
  | "subscription_action"
  | "receipt_flow"
  | "cloud_sync_control";

interface AcceptedEvent {
  readonly id: string;
  readonly identityIdentifier: string;
  readonly occurredAt: number;
  readonly name: AcceptedEventName;
  readonly action: string | null;
  readonly outcome: AcceptedOutcome | null;
  readonly digest: string;
}

interface AcceptedUpload {
  readonly appVersion: string;
  readonly pseudonymousIdentifier: string;
  readonly deletionHandle: string;
  readonly events: AcceptedEvent[];
}

interface AcceptedDeletionProof {
  readonly pseudonymousIdentifier: string;
  readonly deletionHandle: string;
}

type RouteName = "events" | "delete" | "scheduled" | "unknown";
type ReasonCode =
  | "accepted"
  | "deleted"
  | "expired_cleanup"
  | "invalid_host"
  | "invalid_route"
  | "invalid_method"
  | "invalid_headers"
  | "invalid_bytes"
  | "invalid_schema"
  | "identity_conflict"
  | "event_conflict"
  | "proof_conflict"
  | "rate_limited"
  | "storage_unavailable";

class StrictJSONError extends Error {}
class RequestTooLargeError extends Error {}

/** A complete bounded JSON parser that rejects duplicate object keys before JSON semantics can
 * collapse them. It deliberately implements no reviver, comments, non-finite number, or extension.
 */
class StrictJSONReader {
  private index = 0;
  private nodes = 0;

  constructor(private readonly source: string) {}

  parse(): JSONValue {
    this.skipWhitespace();
    const value = this.parseValue(0);
    this.skipWhitespace();
    if (this.index !== this.source.length) throw new StrictJSONError("trailing_bytes");
    return value;
  }

  private parseValue(depth: number): JSONValue {
    if (depth > 10 || ++this.nodes > 512) throw new StrictJSONError("bounded_shape");
    const character = this.source[this.index];
    if (character === "{") return this.parseObject(depth + 1);
    if (character === "[") return this.parseArray(depth + 1);
    if (character === '"') return this.parseString();
    if (character === "t" && this.consumeLiteral("true")) return true;
    if (character === "f" && this.consumeLiteral("false")) return false;
    if (character === "n" && this.consumeLiteral("null")) return null;
    return this.parseNumber();
  }

  private parseObject(depth: number): JSONObject {
    this.index += 1;
    const object: JSONObject = Object.create(null) as JSONObject;
    const keys = new Set<string>();
    this.skipWhitespace();
    if (this.source[this.index] === "}") {
      this.index += 1;
      return object;
    }
    while (true) {
      if (this.source[this.index] !== '"') throw new StrictJSONError("object_key");
      const key = this.parseString();
      if (keys.has(key)) throw new StrictJSONError("duplicate_key");
      keys.add(key);
      this.skipWhitespace();
      if (this.source[this.index] !== ":") throw new StrictJSONError("missing_colon");
      this.index += 1;
      this.skipWhitespace();
      object[key] = this.parseValue(depth);
      this.skipWhitespace();
      const separator = this.source[this.index++];
      if (separator === "}") return object;
      if (separator !== ",") throw new StrictJSONError("object_separator");
      this.skipWhitespace();
    }
  }

  private parseArray(depth: number): JSONValue[] {
    this.index += 1;
    const values: JSONValue[] = [];
    this.skipWhitespace();
    if (this.source[this.index] === "]") {
      this.index += 1;
      return values;
    }
    while (true) {
      values.push(this.parseValue(depth));
      this.skipWhitespace();
      const separator = this.source[this.index++];
      if (separator === "]") return values;
      if (separator !== ",") throw new StrictJSONError("array_separator");
      this.skipWhitespace();
    }
  }

  private parseString(): string {
    const start = this.index;
    this.index += 1;
    while (this.index < this.source.length) {
      const code = this.source.charCodeAt(this.index);
      if (code < 0x20) throw new StrictJSONError("control_character");
      if (this.source[this.index] === '"') {
        this.index += 1;
        try {
          return JSON.parse(this.source.slice(start, this.index)) as string;
        } catch {
          throw new StrictJSONError("invalid_string");
        }
      }
      if (this.source[this.index] === "\\") {
        this.index += 1;
        const escaped = this.source[this.index];
        if (escaped === "u") {
          const scalar = this.source.slice(this.index + 1, this.index + 5);
          if (!/^[0-9a-fA-F]{4}$/.test(scalar)) throw new StrictJSONError("unicode_escape");
          this.index += 5;
          continue;
        }
        if (!['"', "\\", "/", "b", "f", "n", "r", "t"].includes(escaped ?? "")) {
          throw new StrictJSONError("string_escape");
        }
      }
      this.index += 1;
    }
    throw new StrictJSONError("unterminated_string");
  }

  private parseNumber(): number {
    const remaining = this.source.slice(this.index);
    const match = /^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?/.exec(remaining);
    if (match === null) throw new StrictJSONError("invalid_value");
    this.index += match[0].length;
    const value = Number(match[0]);
    if (!Number.isFinite(value)) throw new StrictJSONError("non_finite_number");
    return value;
  }

  private consumeLiteral(literal: string): boolean {
    if (!this.source.startsWith(literal, this.index)) return false;
    this.index += literal.length;
    return true;
  }

  private skipWhitespace(): void {
    while (/[ \t\n\r]/.test(this.source[this.index] ?? "")) this.index += 1;
  }
}

export function operationalLogRecord(
  environment: AcceptedEnvironment,
  route: RouteName,
  reason: ReasonCode,
): Readonly<Record<string, string>> {
  return {
    component: "mindbudget_telemetry_receiver",
    environment,
    route,
    reason,
  };
}

function recordReason(env: WorkerEnvironment, route: RouteName, reason: ReasonCode): void {
  // This closed object is the complete persistent custom-log vocabulary. Never add request facts.
  console.log(operationalLogRecord(env.DEPLOYMENT_ENVIRONMENT, route, reason));
}

function emptyResponse(status: number, extraHeaders?: HeadersInit): Response {
  const headers = new Headers(extraHeaders);
  headers.set("Cache-Control", "no-store");
  headers.set("Content-Length", "0");
  headers.set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'");
  headers.set("Referrer-Policy", "no-referrer");
  headers.set("X-Content-Type-Options", "nosniff");
  return new Response(null, { status, headers });
}

function exactObject(value: JSONValue, keys: readonly string[]): value is JSONObject {
  if (value === null || Array.isArray(value) || typeof value !== "object") return false;
  const actual = Object.keys(value).sort();
  const expected = [...keys].sort();
  return actual.length === expected.length && actual.every((key, index) => key === expected[index]);
}

function normalizedUUID(value: JSONValue): string | null {
  return typeof value === "string" && UUID_V4_PATTERN.test(value) ? value.toLowerCase() : null;
}

function acceptedOutcome(value: JSONValue): value is AcceptedOutcome {
  return typeof value === "string"
    && ["completed", "cancelled", "unavailable", "failed"].includes(value);
}

function acceptedAction(name: AcceptedEventName, value: JSONValue): value is string {
  if (typeof value !== "string") return false;
  switch (name) {
    case "pro_surface": return ["presented", "dismissed"].includes(value);
    case "subscription_action": return ["purchase", "restore", "manage"].includes(value);
    case "receipt_flow": return ["opened", "acquired", "reviewed", "saved"].includes(value);
    case "cloud_sync_control":
      return ["enable", "disable", "deleteCloudCopy", "resolveConflict"].includes(value);
    case "app_session_started": return false;
  }
}

async function sha256Hex(bytes: BufferSource): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

async function validateEvent(
  value: JSONValue,
  pseudonymousIdentifier: string,
  appVersion: string,
  nowMilliseconds: number,
): Promise<AcceptedEvent | null> {
  if (!exactObject(value, ["event", "id", "identityIdentifier", "occurredAt"])) return null;
  const id = normalizedUUID(value.id);
  const identityIdentifier = normalizedUUID(value.identityIdentifier);
  if (id === null || identityIdentifier !== pseudonymousIdentifier) return null;
  if (!Number.isSafeInteger(value.occurredAt)) return null;
  const occurredAt = value.occurredAt as number;
  if (
    occurredAt < nowMilliseconds - RETENTION_MILLISECONDS
    || occurredAt > nowMilliseconds + MAXIMUM_FUTURE_SKEW_MILLISECONDS
  ) return null;
  const event = value.event;
  if (event === null || Array.isArray(event) || typeof event !== "object") return null;
  const name = event.name;
  if (
    typeof name !== "string"
    || ![
      "app_session_started",
      "pro_surface",
      "subscription_action",
      "receipt_flow",
      "cloud_sync_control",
    ].includes(name)
  ) return null;
  const acceptedName = name as AcceptedEventName;
  let action: string | null = null;
  let outcome: AcceptedOutcome | null = null;
  if (acceptedName === "app_session_started") {
    if (!exactObject(event, ["name"])) return null;
  } else if (acceptedName === "pro_surface") {
    if (!exactObject(event, ["action", "name"]) || !acceptedAction(acceptedName, event.action)) {
      return null;
    }
    action = event.action as string;
  } else {
    if (
      !exactObject(event, ["action", "name", "outcome"])
      || !acceptedAction(acceptedName, event.action)
      || !acceptedOutcome(event.outcome)
    ) return null;
    action = event.action as string;
    outcome = event.outcome as AcceptedOutcome;
  }
  const digestBytes = new TextEncoder().encode(JSON.stringify([
    pseudonymousIdentifier,
    appVersion,
    occurredAt,
    acceptedName,
    action,
    outcome,
  ]));
  return {
    id,
    identityIdentifier,
    occurredAt,
    name: acceptedName,
    action,
    outcome,
    digest: await sha256Hex(digestBytes),
  };
}

async function validateUpload(
  value: JSONValue,
  expectedEnvironment: AcceptedEnvironment,
  nowMilliseconds: number,
): Promise<AcceptedUpload | null> {
  if (!exactObject(value, [
    "appVersion",
    "deletionHandle",
    "environment",
    "events",
    "pseudonymousIdentifier",
    "schemaVersion",
  ])) return null;
  if (value.schemaVersion !== 1 || value.environment !== expectedEnvironment) return null;
  if (
    typeof value.appVersion !== "string"
    || value.appVersion.length > 32
    || !APP_VERSION_PATTERN.test(value.appVersion)
  ) return null;
  const pseudonymousIdentifier = normalizedUUID(value.pseudonymousIdentifier);
  if (pseudonymousIdentifier === null) return null;
  if (typeof value.deletionHandle !== "string" || !LOWER_HEX_32_PATTERN.test(value.deletionHandle)) {
    return null;
  }
  if (!Array.isArray(value.events) || value.events.length === 0 || value.events.length > MAXIMUM_BATCH_EVENTS) {
    return null;
  }
  const events: AcceptedEvent[] = [];
  const identifiers = new Set<string>();
  for (const candidate of value.events) {
    const event = await validateEvent(
      candidate,
      pseudonymousIdentifier,
      value.appVersion,
      nowMilliseconds,
    );
    if (event === null || identifiers.has(event.id)) return null;
    identifiers.add(event.id);
    events.push(event);
  }
  return {
    appVersion: value.appVersion,
    pseudonymousIdentifier,
    deletionHandle: value.deletionHandle,
    events,
  };
}

function decode32ByteBase64(value: JSONValue): Uint8Array | null {
  if (typeof value !== "string" || !BASE64_32_PATTERN.test(value)) return null;
  try {
    const binary = atob(value);
    if (binary.length !== 32) return null;
    return Uint8Array.from(binary, (character) => character.charCodeAt(0));
  } catch {
    return null;
  }
}

async function validateDeletion(
  value: JSONValue,
  expectedEnvironment: AcceptedEnvironment,
): Promise<AcceptedDeletionProof[] | null> {
  if (!exactObject(value, ["environment", "proofs", "schemaVersion"])) return null;
  if (value.schemaVersion !== 1 || value.environment !== expectedEnvironment) return null;
  if (!Array.isArray(value.proofs) || value.proofs.length === 0 || value.proofs.length > MAXIMUM_DELETE_PROOFS) {
    return null;
  }
  const proofs: AcceptedDeletionProof[] = [];
  const identifiers = new Set<string>();
  for (const candidate of value.proofs) {
    if (!exactObject(candidate, ["deletionSecret", "pseudonymousIdentifier"])) return null;
    const identifier = normalizedUUID(candidate.pseudonymousIdentifier);
    const secret = decode32ByteBase64(candidate.deletionSecret);
    if (identifier === null || secret === null || identifiers.has(identifier)) return null;
    identifiers.add(identifier);
    proofs.push({ pseudonymousIdentifier: identifier, deletionHandle: await sha256Hex(secret) });
  }
  return proofs;
}

async function readStrictJSON(request: Request, maximumBytes: number): Promise<JSONValue> {
  const length = request.headers.get("Content-Length");
  if (length !== null && (!/^[0-9]+$/.test(length) || Number(length) > maximumBytes)) {
    throw new RequestTooLargeError();
  }
  if (request.body === null) throw new StrictJSONError("missing_body");
  const reader = request.body.getReader();
  const chunks: Uint8Array[] = [];
  let count = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    count += value.byteLength;
    if (count > maximumBytes) {
      await reader.cancel();
      throw new RequestTooLargeError();
    }
    chunks.push(value);
  }
  if (count === 0) throw new StrictJSONError("empty_body");
  const bytes = new Uint8Array(count);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  let source: string;
  try {
    source = new TextDecoder("utf-8", { fatal: true, ignoreBOM: false }).decode(bytes);
  } catch {
    throw new StrictJSONError("invalid_utf8");
  }
  if (source.charCodeAt(0) === 0xfeff) throw new StrictJSONError("byte_order_mark");
  return new StrictJSONReader(source).parse();
}

function hasAcceptedHeaders(request: Request): boolean {
  const acceptLanguage = request.headers.get("Accept-Language");
  if (
    request.headers.get("Content-Type")?.toLowerCase() !== "application/json"
    || request.headers.get("User-Agent") !== FIXED_USER_AGENT
    || (acceptLanguage !== null && acceptLanguage !== "")
    || request.headers.has("Content-Encoding")
    || request.headers.has("Authorization")
    || request.headers.has("Cookie")
  ) return false;
  for (const [name] of request.headers) {
    if (name.toLowerCase().startsWith("x-mindbudget-")) return false;
  }
  return true;
}

/// Tombstones deliberately retain only a coarse UTC-day TTL bucket. Multiple requests accepted
/// on the same UTC day therefore have no request-unique acceptance timestamp to preserve or join.
function tombstoneExpirationBucket(nowMilliseconds: number): number {
  return Math.floor(
    (nowMilliseconds + RETENTION_MILLISECONDS) / UTC_DAY_MILLISECONDS,
  ) * UTC_DAY_MILLISECONDS;
}

async function rateLimitEdge(request: Request, env: WorkerEnvironment, route: RouteName): Promise<boolean> {
  const edgeAddress = request.headers.get("CF-Connecting-IP") ?? "local-development";
  return (await env.TELEMETRY_EDGE_RATE_LIMITER.limit({ key: `${route}:${edgeAddress}` })).success;
}

async function rateLimitIdentities(
  env: WorkerEnvironment,
  route: RouteName,
  identifiers: readonly string[],
): Promise<boolean> {
  for (const identifier of identifiers) {
    if (!(await env.TELEMETRY_IDENTITY_RATE_LIMITER.limit({ key: `${route}:${identifier}` })).success) {
      return false;
    }
  }
  return true;
}

function isD1Conflict(error: unknown, marker: string): boolean {
  return error instanceof Error && error.message.includes(marker);
}

async function storeUpload(
  env: WorkerEnvironment,
  upload: AcceptedUpload,
  nowMilliseconds: number,
): Promise<"accepted" | "identity_conflict" | "event_conflict" | "storage_unavailable"> {
  const expiresAt = nowMilliseconds + RETENTION_MILLISECONDS;
  const identity = upload.pseudonymousIdentifier;
  const handle = upload.deletionHandle;
  const statements: D1PreparedStatement[] = [
    env.TELEMETRY_DB.prepare(
      `DELETE FROM telemetry_events
       WHERE pseudonymous_id = ? AND expires_at_ms <= ?`,
    ).bind(identity, nowMilliseconds),
    env.TELEMETRY_DB.prepare(
      `DELETE FROM telemetry_identities
       WHERE pseudonymous_id = ? AND expires_at_ms <= ?
         AND NOT EXISTS (
           SELECT 1 FROM telemetry_events WHERE pseudonymous_id = ?
         )`,
    ).bind(identity, nowMilliseconds, identity),
    env.TELEMETRY_DB.prepare(
      `DELETE FROM telemetry_deleted_identities
       WHERE pseudonymous_id = ? AND deletion_handle = ? AND expires_at_ms <= ?`,
    ).bind(identity, handle, nowMilliseconds),
    env.TELEMETRY_DB.prepare(
      `INSERT INTO telemetry_identities(pseudonymous_id, deletion_handle, expires_at_ms)
       SELECT ?, ?, ?
       WHERE NOT EXISTS (
         SELECT 1 FROM telemetry_deleted_identities
         WHERE pseudonymous_id = ? AND deletion_handle = ?
       )
       ON CONFLICT(pseudonymous_id) DO UPDATE SET
         expires_at_ms = MAX(expires_at_ms, excluded.expires_at_ms)
       WHERE deletion_handle = excluded.deletion_handle`,
    ).bind(identity, handle, expiresAt, identity, handle),
  ];
  for (const event of upload.events) {
    statements.push(env.TELEMETRY_DB.prepare(
      `INSERT OR IGNORE INTO telemetry_events(
         event_id, pseudonymous_id, app_version, occurred_at_ms, accepted_at_ms, expires_at_ms,
         event_name, action, outcome, event_digest
       )
       SELECT ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
       WHERE EXISTS (
         SELECT 1 FROM telemetry_identities
         WHERE pseudonymous_id = ? AND deletion_handle = ?
       )
       AND NOT EXISTS (
         SELECT 1 FROM telemetry_deleted_identities
         WHERE pseudonymous_id = ? AND deletion_handle = ?
       )`,
    ).bind(
      event.id,
      identity,
      upload.appVersion,
      event.occurredAt,
      nowMilliseconds,
      expiresAt,
      event.name,
      event.action,
      event.outcome,
      event.digest,
      identity,
      handle,
      identity,
      handle,
    ));
  }
  try {
    await env.TELEMETRY_DB.batch(statements);
    return "accepted";
  } catch (error) {
    if (isD1Conflict(error, "telemetry_identity_handle_conflict")) return "identity_conflict";
    if (isD1Conflict(error, "telemetry_event_id_conflict")) return "event_conflict";
    return "storage_unavailable";
  }
}

function suppliedProofCTE(proofCount: number): string {
  return `WITH supplied(pseudonymous_id, deletion_handle) AS (VALUES ${
    Array.from({ length: proofCount }, () => "(?, ?)").join(", ")
  })`;
}

async function deleteProofs(
  env: WorkerEnvironment,
  proofs: readonly AcceptedDeletionProof[],
  nowMilliseconds: number,
): Promise<"deleted" | "proof_conflict" | "storage_unavailable"> {
  const cte = suppliedProofCTE(proofs.length);
  const bindings = proofs.flatMap((proof) => [proof.pseudonymousIdentifier, proof.deletionHandle]);
  const expiresAt = tombstoneExpirationBucket(nowMilliseconds);
  const noMismatch = `NOT EXISTS (
    SELECT 1
    FROM telemetry_identities AS identity
    JOIN supplied ON supplied.pseudonymous_id = identity.pseudonymous_id
    WHERE identity.deletion_handle <> supplied.deletion_handle
  )`;
  const statements = [
    env.TELEMETRY_DB.prepare(
      `${cte}
       INSERT INTO telemetry_deleted_identities(pseudonymous_id, deletion_handle, expires_at_ms)
       SELECT pseudonymous_id, deletion_handle, ? FROM supplied
       WHERE ${noMismatch}
       ON CONFLICT(pseudonymous_id, deletion_handle) DO UPDATE SET
         expires_at_ms = MAX(expires_at_ms, excluded.expires_at_ms)`,
    ).bind(...bindings, expiresAt),
    env.TELEMETRY_DB.prepare(
      `${cte}
       DELETE FROM telemetry_events
       WHERE pseudonymous_id IN (SELECT pseudonymous_id FROM supplied)
         AND ${noMismatch}`,
    ).bind(...bindings),
    env.TELEMETRY_DB.prepare(
      `${cte}
       DELETE FROM telemetry_identities
       WHERE pseudonymous_id IN (SELECT pseudonymous_id FROM supplied)
         AND ${noMismatch}`,
    ).bind(...bindings),
    env.TELEMETRY_DB.prepare(
      `${cte}
       SELECT COUNT(*) AS count
       FROM telemetry_identities AS identity
       JOIN supplied ON supplied.pseudonymous_id = identity.pseudonymous_id
       WHERE identity.deletion_handle <> supplied.deletion_handle`,
    ).bind(...bindings),
  ];
  try {
    const results = await env.TELEMETRY_DB.batch(statements);
    const mismatch = results[3]?.results[0] as { count?: number } | undefined;
    return mismatch?.count === 0 ? "deleted" : "proof_conflict";
  } catch {
    return "storage_unavailable";
  }
}

export async function cleanupExpired(env: WorkerEnvironment, nowMilliseconds: number): Promise<void> {
  while (true) {
    const results = await env.TELEMETRY_DB.batch([
      env.TELEMETRY_DB.prepare(
        `DELETE FROM telemetry_events
         WHERE event_id IN (
           SELECT event_id FROM telemetry_events
           WHERE expires_at_ms <= ?
           ORDER BY expires_at_ms
           LIMIT ?
         )`,
      ).bind(nowMilliseconds, CLEANUP_BATCH_SIZE),
      env.TELEMETRY_DB.prepare(
        `DELETE FROM telemetry_identities
         WHERE pseudonymous_id IN (
           SELECT pseudonymous_id FROM telemetry_identities
           WHERE expires_at_ms <= ?
             AND NOT EXISTS (
               SELECT 1 FROM telemetry_events
               WHERE telemetry_events.pseudonymous_id = telemetry_identities.pseudonymous_id
             )
           ORDER BY expires_at_ms
           LIMIT ?
         )`,
      ).bind(nowMilliseconds, CLEANUP_BATCH_SIZE),
      env.TELEMETRY_DB.prepare(
        `DELETE FROM telemetry_deleted_identities
         WHERE rowid IN (
           SELECT rowid FROM telemetry_deleted_identities
           WHERE expires_at_ms <= ?
           ORDER BY expires_at_ms
           LIMIT ?
         )`,
      ).bind(nowMilliseconds, CLEANUP_BATCH_SIZE),
    ]);
    if (!results.some((result) => result.meta.changes === CLEANUP_BATCH_SIZE)) return;
  }
}

async function handleEvents(
  request: Request,
  env: WorkerEnvironment,
  nowMilliseconds: number,
): Promise<Response> {
  let value: JSONValue;
  try {
    value = await readStrictJSON(request, MAXIMUM_UPLOAD_BYTES);
  } catch (error) {
    const reason = error instanceof RequestTooLargeError ? "invalid_bytes" : "invalid_schema";
    recordReason(env, "events", reason);
    return emptyResponse(error instanceof RequestTooLargeError ? 413 : 400);
  }
  const upload = await validateUpload(value, env.DEPLOYMENT_ENVIRONMENT, nowMilliseconds);
  if (upload === null) {
    recordReason(env, "events", "invalid_schema");
    return emptyResponse(400);
  }
  if (!await rateLimitIdentities(env, "events", [upload.pseudonymousIdentifier])) {
    recordReason(env, "events", "rate_limited");
    return emptyResponse(429, { "Retry-After": "60" });
  }
  const resolution = await storeUpload(env, upload, nowMilliseconds);
  if (resolution === "accepted") {
    recordReason(env, "events", "accepted");
    return emptyResponse(202);
  }
  recordReason(env, "events", resolution);
  if (resolution === "storage_unavailable") return emptyResponse(503, { "Retry-After": "60" });
  return emptyResponse(409);
}

async function handleDelete(
  request: Request,
  env: WorkerEnvironment,
  nowMilliseconds: number,
): Promise<Response> {
  let value: JSONValue;
  try {
    value = await readStrictJSON(request, MAXIMUM_DELETE_BYTES);
  } catch (error) {
    const reason = error instanceof RequestTooLargeError ? "invalid_bytes" : "invalid_schema";
    recordReason(env, "delete", reason);
    return emptyResponse(error instanceof RequestTooLargeError ? 413 : 400);
  }
  const proofs = await validateDeletion(value, env.DEPLOYMENT_ENVIRONMENT);
  if (proofs === null) {
    recordReason(env, "delete", "invalid_schema");
    return emptyResponse(400);
  }
  if (!await rateLimitIdentities(env, "delete", proofs.map((proof) => proof.pseudonymousIdentifier))) {
    recordReason(env, "delete", "rate_limited");
    return emptyResponse(429, { "Retry-After": "60" });
  }
  const resolution = await deleteProofs(env, proofs, nowMilliseconds);
  if (resolution === "deleted") {
    recordReason(env, "delete", "deleted");
    return emptyResponse(204);
  }
  recordReason(env, "delete", resolution);
  if (resolution === "storage_unavailable") return emptyResponse(503, { "Retry-After": "60" });
  return emptyResponse(409);
}

export async function handleRequest(
  request: Request,
  env: WorkerEnvironment,
  nowMilliseconds: number = Date.now(),
): Promise<Response> {
  const url = new URL(request.url);
  const route: RouteName = url.pathname === EVENTS_PATH
    ? "events"
    : url.pathname === DELETE_PATH ? "delete" : "unknown";
  if (url.protocol !== "https:" || url.hostname !== env.EXPECTED_HOST) {
    recordReason(env, route, "invalid_host");
    return emptyResponse(421);
  }
  if (route === "unknown" || url.search !== "") {
    recordReason(env, route, "invalid_route");
    return emptyResponse(404);
  }
  if (request.method !== "POST") {
    recordReason(env, route, "invalid_method");
    return emptyResponse(405, { Allow: "POST" });
  }
  if (!hasAcceptedHeaders(request)) {
    recordReason(env, route, "invalid_headers");
    return emptyResponse(400);
  }
  if (!await rateLimitEdge(request, env, route)) {
    recordReason(env, route, "rate_limited");
    return emptyResponse(429, { "Retry-After": "60" });
  }
  return route === "events"
    ? handleEvents(request, env, nowMilliseconds)
    : handleDelete(request, env, nowMilliseconds);
}

export default {
  fetch(request, env) {
    return handleRequest(request, env);
  },
  async scheduled(controller, env) {
    try {
      await cleanupExpired(env, controller.scheduledTime);
      recordReason(env, "scheduled", "expired_cleanup");
    } catch {
      recordReason(env, "scheduled", "storage_unavailable");
      throw new Error("telemetry_cleanup_failed");
    }
  },
} satisfies ExportedHandler<Env>;
