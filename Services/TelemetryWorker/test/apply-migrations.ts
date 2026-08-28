import { applyD1Migrations, env } from "cloudflare:test";
import type { D1Migration } from "cloudflare:test";

const testEnvironment = env as Env & { TEST_MIGRATIONS: D1Migration[] };
await applyD1Migrations(testEnvironment.TELEMETRY_DB, testEnvironment.TEST_MIGRATIONS);
