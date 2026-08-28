import { env } from "cloudflare:test";
import { beforeEach, describe, expect, it } from "vitest";
import { cleanupExpired, handleRequest, operationalLogRecord } from "../src/index";

const endpoint = "https://mindbudget-telemetry.yehao1105.workers.dev";
const now = 1_800_000_000_000;
const firstIdentity = "11111111-1111-4111-8111-111111111111";
const secondIdentity = "22222222-2222-4222-8222-222222222222";
const firstEvent = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const secondEvent = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
const firstSecret = Uint8Array.from({ length: 32 }, (_, index) => index + 1);
const secondSecret = Uint8Array.from({ length: 32 }, (_, index) => 255 - index);

function base64(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes));
}

async function handle(bytes: Uint8Array): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

async function uploadBody(
  identity: string = firstIdentity,
  eventID: string = firstEvent,
  event: Record<string, string> = { name: "app_session_started" },
  secret: Uint8Array = firstSecret,
): Promise<Record<string, unknown>> {
  return {
    appVersion: "1.0.0",
    deletionHandle: await handle(secret),
    environment: "production",
    events: [{
      event,
      id: eventID,
      identityIdentifier: identity,
      occurredAt: now,
    }],
    pseudonymousIdentifier: identity,
    schemaVersion: 1,
  };
}

function deletionBody(proofs: Array<{ identity: string; secret: Uint8Array }>): Record<string, unknown> {
  return {
    environment: "production",
    proofs: proofs.map((proof) => ({
      deletionSecret: base64(proof.secret),
      pseudonymousIdentifier: proof.identity,
    })),
    schemaVersion: 1,
  };
}

function request(path: string, body: unknown, headers: HeadersInit = {}): Request {
  return new Request(`${endpoint}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", ...headers },
    body: typeof body === "string" ? body : JSON.stringify(body),
  });
}

async function rowCount(table: string): Promise<number> {
  const result = await env.TELEMETRY_DB.prepare(`SELECT COUNT(*) AS count FROM ${table}`).first<{
    count: number;
  }>();
  return result?.count ?? -1;
}

describe("MindBudget telemetry Worker", () => {
  beforeEach(async () => {
    await env.TELEMETRY_DB.batch([
      env.TELEMETRY_DB.prepare("DELETE FROM telemetry_events"),
      env.TELEMETRY_DB.prepare("DELETE FROM telemetry_identities"),
      env.TELEMETRY_DB.prepare("DELETE FROM telemetry_deleted_identities"),
    ]);
  });

  it("accepts exact closed events and keeps identical retries idempotent", async () => {
    const body = await uploadBody();
    const first = await handleRequest(request("/v1/events", body), env, now);
    const retry = await handleRequest(request("/v1/events", body), env, now + 1);

    expect(first.status).toBe(202);
    expect(retry.status).toBe(202);
    expect(await first.text()).toBe("");
    expect(first.headers.get("Cache-Control")).toBe("no-store");
    expect(await rowCount("telemetry_events")).toBe(1);
    expect(await rowCount("telemetry_identities")).toBe(1);
    const stored = await env.TELEMETRY_DB.prepare(
      `SELECT event_name, action, outcome, accepted_at_ms, expires_at_ms
       FROM telemetry_events WHERE event_id = ?`,
    ).bind(firstEvent).first<Record<string, unknown>>();
    expect(stored).toMatchObject({
      event_name: "app_session_started",
      action: null,
      outcome: null,
      accepted_at_ms: expect.any(Number),
      expires_at_ms: expect.any(Number),
    });
  });

  it("rolls back a whole batch when one accepted event ID changes facts", async () => {
    expect((await handleRequest(request("/v1/events", await uploadBody()), env, now)).status).toBe(202);
    const conflicting = await uploadBody(firstIdentity, firstEvent, {
      action: "presented",
      name: "pro_surface",
    });
    (conflicting.events as Array<Record<string, unknown>>).unshift({
      event: { name: "app_session_started" },
      id: secondEvent,
      identityIdentifier: firstIdentity,
      occurredAt: now,
    });

    const response = await handleRequest(request("/v1/events", conflicting), env, now);

    expect(response.status).toBe(409);
    expect(await rowCount("telemetry_events")).toBe(1);
    expect(await env.TELEMETRY_DB.prepare(
      "SELECT 1 AS found FROM telemetry_events WHERE event_id = ?",
    ).bind(secondEvent).first()).toBeNull();
  });

  it("treats an app-version change as conflicting facts for the same event ID", async () => {
    expect((await handleRequest(request("/v1/events", await uploadBody()), env, now)).status).toBe(202);
    const conflicting = await uploadBody();
    conflicting.appVersion = "1.0.1";

    const response = await handleRequest(request("/v1/events", conflicting), env, now + 1);

    expect(response.status).toBe(409);
    const stored = await env.TELEMETRY_DB.prepare(
      "SELECT app_version FROM telemetry_events WHERE event_id = ?",
    ).bind(firstEvent).first<{ app_version: string }>();
    expect(stored?.app_version).toBe("1.0.0");
  });

  it("rejects a pseudonym reused with a different deletion handle", async () => {
    expect((await handleRequest(request("/v1/events", await uploadBody()), env, now)).status).toBe(202);
    const response = await handleRequest(
      request("/v1/events", await uploadBody(firstIdentity, secondEvent, undefined, secondSecret)),
      env,
      now,
    );

    expect(response.status).toBe(409);
    expect(await rowCount("telemetry_events")).toBe(1);
  });

  it.each([
    ["unknown top-level field", async () => ({ ...await uploadBody(), merchant: "forbidden" })],
    ["unknown event field", async () => {
      const body = await uploadBody();
      (body.events as Array<Record<string, unknown>>)[0] = {
        ...(body.events as Array<Record<string, unknown>>)[0],
        note: "forbidden",
      };
      return body;
    }],
    ["free-text event", async () => uploadBody(firstIdentity, firstEvent, { name: "caller_text" })],
    ["wrong environment", async () => ({ ...await uploadBody(), environment: "development" })],
    ["non-v4 identifier", async () => uploadBody("11111111-1111-1111-8111-111111111111")],
    ["future occurrence", async () => {
      const body = await uploadBody();
      (body.events as Array<Record<string, unknown>>)[0].occurredAt = now + 601_000;
      return body;
    }],
  ])("rejects %s without a write", async (_name, makeBody) => {
    const response = await handleRequest(request("/v1/events", await makeBody()), env, now);
    expect(response.status).toBe(400);
    expect(await rowCount("telemetry_events")).toBe(0);
  });

  it("rejects duplicate JSON keys before parser semantics can collapse them", async () => {
    const body = JSON.stringify(await uploadBody());
    const duplicate = body.replace('"schemaVersion":1', '"schemaVersion":1,"schemaVersion":1');
    const response = await handleRequest(request("/v1/events", duplicate), env, now);
    expect(response.status).toBe(400);
    expect(await rowCount("telemetry_events")).toBe(0);
  });

  it.each([
    ["wrong host", new Request("https://example.invalid/v1/events", { method: "POST" }), 421],
    ["wrong path", request("/v2/events", {}), 404],
    ["query", new Request(`${endpoint}/v1/events?device=1`, {
      method: "POST", headers: { "Content-Type": "application/json" }, body: "{}",
    }), 404],
    ["wrong method", new Request(`${endpoint}/v1/events`), 405],
    ["authorization", request("/v1/events", {}, { Authorization: "Bearer forbidden" }), 400],
    ["cookie", request("/v1/events", {}, { Cookie: "forbidden=1" }), 400],
    ["content encoding", request("/v1/events", {}, { "Content-Encoding": "gzip" }), 400],
    ["custom app header", request("/v1/events", {}, { "X-MindBudget-Device": "forbidden" }), 400],
  ])("rejects %s with an empty response", async (_name, candidate, status) => {
    const response = await handleRequest(candidate, env);
    expect(response.status).toBe(status);
    expect(await response.text()).toBe("");
  });

  it("stops reading an oversized upload before schema processing", async () => {
    const response = await handleRequest(request("/v1/events", "x".repeat(32 * 1024 + 1)), env);
    expect(response.status).toBe(413);
    expect(await rowCount("telemetry_events")).toBe(0);
  });

  it("deletes every valid proof atomically, keeps no group, and accepts an identical retry", async () => {
    expect((await handleRequest(request("/v1/events", await uploadBody()), env, now)).status).toBe(202);
    expect((await handleRequest(
      request("/v1/events", await uploadBody(secondIdentity, secondEvent, undefined, secondSecret)),
      env,
      now,
    )).status).toBe(202);
    const body = deletionBody([
      { identity: firstIdentity, secret: firstSecret },
      { identity: secondIdentity, secret: secondSecret },
    ]);

    const first = await handleRequest(request("/v1/delete", body), env, now + 1);
    const retry = await handleRequest(request("/v1/delete", body), env, now + 2);

    expect(first.status).toBe(204);
    expect(retry.status).toBe(204);
    expect(await rowCount("telemetry_events")).toBe(0);
    expect(await rowCount("telemetry_identities")).toBe(0);
    expect(await rowCount("telemetry_deleted_identities")).toBe(2);
    const tables = await env.TELEMETRY_DB.prepare(
      "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
    ).all<{ name: string }>();
    expect(tables.results.map((row) => row.name)).not.toContain("telemetry_deletion_requests");
  });

  it("rejects one invalid proof without partially deleting the other identity", async () => {
    expect((await handleRequest(request("/v1/events", await uploadBody()), env, now)).status).toBe(202);
    expect((await handleRequest(
      request("/v1/events", await uploadBody(secondIdentity, secondEvent, undefined, secondSecret)),
      env,
      now,
    )).status).toBe(202);
    const body = deletionBody([
      { identity: firstIdentity, secret: firstSecret },
      { identity: secondIdentity, secret: firstSecret },
    ]);

    const response = await handleRequest(request("/v1/delete", body), env, now + 1);

    expect(response.status).toBe(409);
    expect(await rowCount("telemetry_events")).toBe(2);
    expect(await rowCount("telemetry_identities")).toBe(2);
    expect(await rowCount("telemetry_deleted_identities")).toBe(0);
  });

  it("accepts but discards a late matching upload after deletion", async () => {
    const upload = await uploadBody();
    expect((await handleRequest(request("/v1/events", upload), env, now)).status).toBe(202);
    expect((await handleRequest(
      request("/v1/delete", deletionBody([{ identity: firstIdentity, secret: firstSecret }])),
      env,
      now + 1,
    )).status).toBe(204);

    const late = await handleRequest(request("/v1/events", upload), env, now + 2);

    expect(late.status).toBe(202);
    expect(await rowCount("telemetry_events")).toBe(0);
    expect(await rowCount("telemetry_identities")).toBe(0);
    expect(await rowCount("telemetry_deleted_identities")).toBe(1);
  });

  it("removes expired events, independent identities, and tombstones in bounded cleanup", async () => {
    const upload = await uploadBody();
    expect((await handleRequest(request("/v1/events", upload), env, now)).status).toBe(202);
    expect((await handleRequest(
      request("/v1/delete", deletionBody([{ identity: secondIdentity, secret: secondSecret }])),
      env,
      now,
    )).status).toBe(204);

    await cleanupExpired(env, now + 90 * 24 * 60 * 60 * 1000 + 1);

    expect(await rowCount("telemetry_events")).toBe(0);
    expect(await rowCount("telemetry_identities")).toBe(0);
    expect(await rowCount("telemetry_deleted_identities")).toBe(0);
  });

  it("applies edge and identity limiters only as empty retry responses", async () => {
    const observed: string[] = [];
    const limitedEnvironment = {
      ...env,
      TELEMETRY_EDGE_RATE_LIMITER: {
        async limit(input: { key: string }) {
          observed.push(input.key);
          return { success: false };
        },
      },
    } as unknown as Env;
    const response = await handleRequest(
      request("/v1/events", await uploadBody(), { "CF-Connecting-IP": "203.0.113.10" }),
      limitedEnvironment,
      now,
    );

    expect(response.status).toBe(429);
    expect(response.headers.get("Retry-After")).toBe("60");
    expect(await response.text()).toBe("");
    expect(observed).toEqual(["events:203.0.113.10"]);
    expect(await rowCount("telemetry_events")).toBe(0);
  });

  it("persists only the closed operational log object", async () => {
    const record = operationalLogRecord("production", "events", "accepted");
    expect(record).toEqual({
      component: "mindbudget_telemetry_receiver",
      environment: "production",
      route: "events",
      reason: "accepted",
    });
    expect(JSON.stringify(record)).not.toContain(firstIdentity);
    expect(JSON.stringify(record)).not.toContain(firstEvent);
  });
});
