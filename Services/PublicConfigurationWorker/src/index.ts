const CONFIGURATION_PATH = "/v1/config";
const APP_VERSION_HEADER = "X-MindBudget-App-Version";
const CONFIG_VERSION_HEADER = "X-MindBudget-Config-Version";
const UINT64_MAX = 18_446_744_073_709_551_615n;
const APP_VERSION_PATTERN = /^[0-9A-Za-z][0-9A-Za-z._-]*$/;
const CONFIG_VERSION_PATTERN = /^[1-9][0-9]{0,19}$/;

type WorkerEnvironment = Pick<
  Env,
  | "DEPLOYMENT_ENVIRONMENT"
  | "EXPECTED_HOST"
  | "PUBLIC_CONFIG_PAYLOAD_BASE64"
  | "PUBLIC_CONFIG_SIGNATURE_BASE64"
  | "PUBLIC_CONFIG_RATE_LIMITER"
>;

function emptyResponse(status: number, extraHeaders?: HeadersInit): Response {
  const headers = new Headers(extraHeaders);
  headers.set("Cache-Control", "no-store");
  headers.set("Content-Length", "0");
  headers.set("Referrer-Policy", "no-referrer");
  headers.set("X-Content-Type-Options", "nosniff");
  return new Response(null, { status, headers });
}

function hasOnlyAcceptedMindBudgetHeaders(headers: Headers): boolean {
  for (const [name] of headers) {
    const normalized = name.toLowerCase();
    if (
      normalized.startsWith("x-mindbudget-") &&
      normalized !== APP_VERSION_HEADER.toLowerCase() &&
      normalized !== CONFIG_VERSION_HEADER.toLowerCase()
    ) {
      return false;
    }
  }
  return true;
}

function hasValidRequestMetadata(request: Request): boolean {
  const appVersion = request.headers.get(APP_VERSION_HEADER);
  if (
    appVersion === null ||
    appVersion.length === 0 ||
    appVersion.length > 32 ||
    !APP_VERSION_PATTERN.test(appVersion)
  ) {
    return false;
  }

  const configVersion = request.headers.get(CONFIG_VERSION_HEADER);
  if (configVersion !== null) {
    if (!CONFIG_VERSION_PATTERN.test(configVersion)) return false;
    try {
      if (BigInt(configVersion) > UINT64_MAX) return false;
    } catch {
      return false;
    }
  }

  return hasOnlyAcceptedMindBudgetHeaders(request.headers);
}

function signedEnvelope(env: WorkerEnvironment): string {
  return JSON.stringify({
    algorithm: "Ed25519",
    keyID: "mb-config-2026-01",
    payloadBase64: env.PUBLIC_CONFIG_PAYLOAD_BASE64,
    signatureBase64: env.PUBLIC_CONFIG_SIGNATURE_BASE64,
  });
}

async function handleRequest(request: Request, env: WorkerEnvironment): Promise<Response> {
  const url = new URL(request.url);
  if (url.protocol !== "https:" || url.hostname !== env.EXPECTED_HOST) {
    return emptyResponse(421);
  }
  if (url.pathname !== CONFIGURATION_PATH || url.search !== "") {
    return emptyResponse(404);
  }
  if (request.method !== "GET") {
    return emptyResponse(405, { Allow: "GET" });
  }
  if (
    request.body !== null ||
    request.headers.has("Authorization") ||
    request.headers.has("Cookie") ||
    request.headers.has("Content-Type") ||
    !hasValidRequestMetadata(request)
  ) {
    return emptyResponse(400);
  }

  // Cloudflare supplies this edge-derived address. It is used only as an ephemeral abuse key;
  // the Worker never logs, persists, returns, or combines it with application metadata.
  const abuseKey = request.headers.get("CF-Connecting-IP") ?? "local-development";
  const rateLimit = await env.PUBLIC_CONFIG_RATE_LIMITER.limit({ key: abuseKey });
  if (!rateLimit.success) {
    return emptyResponse(429, { "Retry-After": "60" });
  }

  const body = signedEnvelope(env);
  return new Response(body, {
    status: 200,
    headers: {
      "Cache-Control": "no-store",
      "Content-Security-Policy": "default-src 'none'; base-uri 'none'; frame-ancestors 'none'",
      "Content-Type": "application/json; charset=utf-8",
      "Cross-Origin-Resource-Policy": "same-site",
      "Referrer-Policy": "no-referrer",
      "X-Content-Type-Options": "nosniff",
    },
  });
}

export default {
  fetch(request, env) {
    return handleRequest(request, env);
  },
} satisfies ExportedHandler<Env>;
