import { env, SELF } from "cloudflare:test";
import { describe, expect, it } from "vitest";
import worker from "../src/index";

const endpoint = "https://mindbudget-public-config.yehao1105.workers.dev/v1/config";
const acceptedHeaders = {
  "X-MindBudget-App-Version": "0.9.6",
  "X-MindBudget-Config-Version": "1",
};

describe("MindBudget public configuration Worker", () => {
  it("returns only the pre-signed envelope on the exact anonymous request", async () => {
    const response = await SELF.fetch(endpoint, { headers: acceptedHeaders });
    const body = (await response.json()) as Record<string, unknown>;

    expect(response.status).toBe(200);
    expect(response.headers.get("Content-Type")).toBe("application/json; charset=utf-8");
    expect(response.headers.get("Cache-Control")).toBe("no-store");
    expect(response.headers.get("Set-Cookie")).toBeNull();
    expect(response.headers.get("Access-Control-Allow-Origin")).toBeNull();
    expect(Object.keys(body).sort()).toEqual([
      "algorithm",
      "keyID",
      "payloadBase64",
      "signatureBase64",
    ]);
    expect(body.algorithm).toBe("Ed25519");
    expect(body.keyID).toBe("mb-config-2026-01");
    expect(body.payloadBase64).toBe(env.PUBLIC_CONFIG_PAYLOAD_BASE64);
    expect(body.signatureBase64).toBe(env.PUBLIC_CONFIG_SIGNATURE_BASE64);
  });

  it.each([
    ["wrong host", "https://example.invalid/v1/config", { headers: acceptedHeaders }, 421],
    ["wrong path", "https://mindbudget-public-config.yehao1105.workers.dev/v2/config", { headers: acceptedHeaders }, 404],
    ["query", `${endpoint}?device=1`, { headers: acceptedHeaders }, 404],
    ["wrong method", endpoint, { method: "POST", headers: acceptedHeaders }, 405],
    ["missing app version", endpoint, {}, 400],
    ["invalid app version", endpoint, { headers: { "X-MindBudget-App-Version": "0.9.6 user" } }, 400],
    ["zero config version", endpoint, { headers: { ...acceptedHeaders, "X-MindBudget-Config-Version": "0" } }, 400],
    ["overflow config version", endpoint, { headers: { ...acceptedHeaders, "X-MindBudget-Config-Version": "18446744073709551616" } }, 400],
    ["unknown app header", endpoint, { headers: { ...acceptedHeaders, "X-MindBudget-Device": "stable" } }, 400],
    ["authorization", endpoint, { headers: { ...acceptedHeaders, Authorization: "Bearer forbidden" } }, 400],
    ["cookie", endpoint, { headers: { ...acceptedHeaders, Cookie: "forbidden=1" } }, 400],
  ])("rejects %s without a response body", async (_name, url, init, status) => {
    const response = await SELF.fetch(url as string, init as RequestInit);
    expect(response.status).toBe(status);
    expect(await response.text()).toBe("");
    expect(response.headers.get("Cache-Control")).toBe("no-store");
  });

  it("uses the edge address only as an opaque limiter key and returns no content when limited", async () => {
    let observedKey: string | undefined;
    const limitedEnvironment = {
      ...env,
      PUBLIC_CONFIG_RATE_LIMITER: {
        async limit(input: { key: string }) {
          observedKey = input.key;
          return { success: false };
        },
      },
    } as unknown as Env;
    const response = await worker.fetch(
      new Request(endpoint, {
        headers: { ...acceptedHeaders, "CF-Connecting-IP": "203.0.113.10" },
      }),
      limitedEnvironment,
    );

    expect(observedKey).toBe("203.0.113.10");
    expect(response.status).toBe(429);
    expect(response.headers.get("Retry-After")).toBe("60");
    expect(await response.text()).toBe("");
  });
});
