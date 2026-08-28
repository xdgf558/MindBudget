import { env } from "cloudflare:test";
import { beforeEach, describe, expect, it } from "vitest";
import { receiptFunnelCounts } from "../src/metrics";

const start = 1_800_000_000_000;
const end = start + 24 * 60 * 60 * 1000;

async function insertIdentity(identifier: string, marker: number): Promise<void> {
  await env.TELEMETRY_DB.prepare(
    `INSERT INTO telemetry_identities(pseudonymous_id, deletion_handle, expires_at_ms)
     VALUES (?, ?, ?)`,
  ).bind(identifier, marker.toString(16).padStart(64, "0"), end + 1).run();
}

async function insertReceiptEvent(
  identifier: string,
  eventIdentifier: string,
  marker: number,
  occurredAt: number,
  action: string,
  outcome: string = "completed",
  appVersion: string = "1.0.0",
): Promise<void> {
  await env.TELEMETRY_DB.prepare(
    `INSERT INTO telemetry_events(
       event_id, pseudonymous_id, app_version, occurred_at_ms, accepted_at_ms, expires_at_ms,
       event_name, action, outcome, event_digest
     ) VALUES (?, ?, ?, ?, ?, ?, 'receipt_flow', ?, ?, ?)`,
  ).bind(
    eventIdentifier,
    identifier,
    appVersion,
    occurredAt,
    occurredAt,
    end + 1,
    action,
    outcome,
    marker.toString(16).padStart(64, "0"),
  ).run();
}

describe("C5-03 receipt funnel evidence", () => {
  beforeEach(async () => {
    await env.TELEMETRY_DB.batch([
      env.TELEMETRY_DB.prepare("DELETE FROM telemetry_events"),
      env.TELEMETRY_DB.prepare("DELETE FROM telemetry_identities"),
      env.TELEMETRY_DB.prepare("DELETE FROM telemetry_deleted_identities"),
    ]);
  });

  it("counts only ordered completed stages in one app-version and half-open window", async () => {
    const complete = "11111111-1111-4111-8111-111111111111";
    const outOfOrder = "22222222-2222-4222-8222-222222222222";
    const cancelled = "33333333-3333-4333-8333-333333333333";
    const otherVersion = "44444444-4444-4444-8444-444444444444";
    const endBoundary = "55555555-5555-4555-8555-555555555555";
    for (const [index, identifier] of [
      complete,
      outOfOrder,
      cancelled,
      otherVersion,
      endBoundary,
    ].entries()) await insertIdentity(identifier, index + 1);

    await insertReceiptEvent(complete, "10000000-0000-4000-8000-000000000001", 1, start + 1, "opened");
    await insertReceiptEvent(complete, "10000000-0000-4000-8000-000000000002", 2, start + 2, "acquired");
    await insertReceiptEvent(complete, "10000000-0000-4000-8000-000000000003", 3, start + 3, "reviewed");
    await insertReceiptEvent(complete, "10000000-0000-4000-8000-000000000004", 4, start + 4, "saved");

    await insertReceiptEvent(outOfOrder, "20000000-0000-4000-8000-000000000001", 5, start + 10, "opened");
    await insertReceiptEvent(outOfOrder, "20000000-0000-4000-8000-000000000002", 6, start + 20, "reviewed");
    await insertReceiptEvent(outOfOrder, "20000000-0000-4000-8000-000000000003", 7, start + 30, "acquired");
    await insertReceiptEvent(outOfOrder, "20000000-0000-4000-8000-000000000004", 8, start + 40, "saved");

    await insertReceiptEvent(cancelled, "30000000-0000-4000-8000-000000000001", 9, start + 5, "opened");
    await insertReceiptEvent(
      cancelled,
      "30000000-0000-4000-8000-000000000002",
      10,
      start + 6,
      "acquired",
      "cancelled",
    );

    await insertReceiptEvent(
      otherVersion,
      "40000000-0000-4000-8000-000000000001",
      11,
      start + 1,
      "opened",
      "completed",
      "2.0.0",
    );
    await insertReceiptEvent(
      endBoundary,
      "50000000-0000-4000-8000-000000000001",
      12,
      end,
      "opened",
    );

    await expect(receiptFunnelCounts(env.TELEMETRY_DB, {
      appVersion: "1.0.0",
      startMilliseconds: start,
      endMilliseconds: end,
    })).resolves.toEqual({
      openedGenerations: 3,
      acquiredGenerations: 2,
      reviewedGenerations: 1,
      savedGenerations: 1,
    });
  });

  it("accepts a later valid chain without letting a premature stage satisfy it", async () => {
    const identifier = "66666666-6666-4666-8666-666666666666";
    await insertIdentity(identifier, 20);
    await insertReceiptEvent(identifier, "60000000-0000-4000-8000-000000000001", 21, start + 1, "reviewed");
    await insertReceiptEvent(identifier, "60000000-0000-4000-8000-000000000002", 22, start + 2, "opened");
    await insertReceiptEvent(identifier, "60000000-0000-4000-8000-000000000003", 23, start + 3, "acquired");
    await insertReceiptEvent(identifier, "60000000-0000-4000-8000-000000000004", 24, start + 4, "reviewed");
    await insertReceiptEvent(identifier, "60000000-0000-4000-8000-000000000005", 25, start + 5, "saved");

    await expect(receiptFunnelCounts(env.TELEMETRY_DB, {
      appVersion: "1.0.0",
      startMilliseconds: start,
      endMilliseconds: end,
    })).resolves.toEqual({
      openedGenerations: 1,
      acquiredGenerations: 1,
      reviewedGenerations: 1,
      savedGenerations: 1,
    });
  });

  it("rejects malformed, empty, reversed, and over-retention scopes", async () => {
    const valid = { appVersion: "1.0.0", startMilliseconds: start, endMilliseconds: end };
    await expect(receiptFunnelCounts(env.TELEMETRY_DB, { ...valid, appVersion: "1 beta" }))
      .rejects.toThrow("invalid_receipt_funnel_scope");
    await expect(receiptFunnelCounts(env.TELEMETRY_DB, { ...valid, endMilliseconds: start }))
      .rejects.toThrow("invalid_receipt_funnel_scope");
    await expect(receiptFunnelCounts(env.TELEMETRY_DB, {
      ...valid,
      endMilliseconds: start + 90 * 24 * 60 * 60 * 1000 + 1,
    })).rejects.toThrow("invalid_receipt_funnel_scope");
  });
});
