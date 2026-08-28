import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import {
  buildEvidenceBundle,
  canonicalEvidenceJSON,
  wilson95BasisPoints,
} from "../tools/build-c5-evidence.mjs";

const digests = Object.freeze({
  app_store_connect_analytics: "1".repeat(64),
  first_party_telemetry_aggregate: "2".repeat(64),
  voluntary_survey_aggregate: "3".repeat(64),
});

const metricSources = Object.freeze({
  app_store_download_conversion: "app_store_connect_analytics",
  app_store_trial_to_paid: "app_store_connect_analytics",
  app_store_usage_opt_in: "app_store_connect_analytics",
  receipt_acquired_from_opened: "first_party_telemetry_aggregate",
  receipt_reviewed_from_acquired: "first_party_telemetry_aggregate",
  receipt_saved_from_reviewed: "first_party_telemetry_aggregate",
  survey_response_rate: "voluntary_survey_aggregate",
  survey_pro_value_positive: "voluntary_survey_aggregate",
  survey_receipt_value_positive: "voluntary_survey_aggregate",
});

function availableMetric(id, numerator = 50, denominator = 100, sampleSize = 100) {
  const source = metricSources[id];
  return {
    artifactSHA256: digests[source],
    denominator,
    id,
    numerator,
    sampleSize,
    source,
    status: "available",
  };
}

function input() {
  return {
    evaluatedAppVersion: "1.0.0",
    evidenceVersion: "c5-03-v1",
    generatedAt: "2026-08-29T00:00:00Z",
    observationWindow: { end: "2026-08-28T00:00:00Z", start: "2026-08-01T00:00:00Z" },
    schemaVersion: 1,
    segments: [{
      appVersion: "1.0.0",
      deviceFamily: "iPhone",
      environment: "production",
      metrics: Object.keys(metricSources).map((id) => availableMetric(id)),
      storefront: "ALL",
    }],
    sourceArtifacts: Object.entries(digests).map(([kind, sha256]) => ({
      exportedAt: "2026-08-28T12:00:00Z",
      kind,
      sha256,
    })),
    telemetrySchemaVersion: 1,
  };
}

test("uses a fixed outward-rounded Wilson 95 percent interval", () => {
  assert.deepEqual(wilson95BasisPoints(50, 100), {
    estimateBasisPoints: 5000,
    lowerBasisPoints: 4038,
    upperBasisPoints: 5962,
  });
  assert.deepEqual(wilson95BasisPoints(0, 10), {
    estimateBasisPoints: 0,
    lowerBasisPoints: 0,
    upperBasisPoints: 2776,
  });
});

test("builds complete deterministic rows with exact counts and source digests", () => {
  const first = buildEvidenceBundle(input());
  const secondInput = input();
  secondInput.segments[0].metrics.reverse();
  secondInput.sourceArtifacts.reverse();
  const second = buildEvidenceBundle(secondInput);

  assert.equal(first.coverage.availableMetricCount, 9);
  assert.equal(first.coverage.requiredMetricCount, 9);
  assert.equal(first.coverage.availableRatioBasisPoints, 10_000);
  assert.equal(first.segments[0].metrics[0].id, "app_store_download_conversion");
  assert.equal(first.segments[0].metrics[0].confidenceInterval95.lowerBasisPoints, 4038);
  assert.equal(canonicalEvidenceJSON(first), canonicalEvidenceJSON(second));
});

test("distinguishes Apple suppression, a proven zero denominator, and no collection", () => {
  const candidate = input();
  candidate.segments[0].metrics[0] = {
    artifactSHA256: digests.app_store_connect_analytics,
    denominator: null,
    id: "app_store_download_conversion",
    numerator: null,
    sampleSize: null,
    source: "app_store_connect_analytics",
    status: "source_suppressed",
  };
  candidate.segments[0].metrics[3] = {
    artifactSHA256: digests.first_party_telemetry_aggregate,
    denominator: 0,
    id: "receipt_acquired_from_opened",
    numerator: 0,
    sampleSize: 0,
    source: "first_party_telemetry_aggregate",
    status: "zero_denominator",
  };
  candidate.segments[0].metrics[6] = {
    artifactSHA256: null,
    denominator: null,
    id: "survey_response_rate",
    numerator: null,
    sampleSize: null,
    source: "voluntary_survey_aggregate",
    status: "not_collected",
  };

  const result = buildEvidenceBundle(candidate);
  assert.equal(result.coverage.availableMetricCount, 6);
  assert.equal(result.coverage.evidenceBearingMetricCount, 8);
  assert.equal(result.segments[0].metrics.find((row) => row.id === "app_store_download_conversion").estimateBasisPoints, null);
  assert.equal(result.segments[0].metrics.find((row) => row.id === "receipt_acquired_from_opened").denominator, 0);
  assert.equal(result.segments[0].metrics.find((row) => row.id === "survey_response_rate").artifactSHA256, null);
});

test("rejects missing metrics, impossible counts, and source-digest substitution", () => {
  const missing = input();
  missing.segments[0].metrics.pop();
  assert.throws(() => buildEvidenceBundle(missing), /segment_metric_count/);

  const impossible = input();
  impossible.segments[0].metrics[0].numerator = 101;
  assert.throws(() => buildEvidenceBundle(impossible), /metric_fraction/);

  const substituted = input();
  substituted.segments[0].metrics[0].artifactSHA256 = digests.first_party_telemetry_aggregate;
  assert.throws(() => buildEvidenceBundle(substituted), /metric_artifact_source/);
});

test("rejects unknown fields and normalized or overlong observation windows", () => {
  const unknown = input();
  unknown.customerID = "forbidden";
  assert.throws(() => buildEvidenceBundle(unknown), /root_shape/);

  const invalidDate = input();
  invalidDate.observationWindow.start = "2026-02-30T00:00:00Z";
  assert.throws(() => buildEvidenceBundle(invalidDate), /window_start/);

  const overlong = input();
  overlong.observationWindow.start = "2026-05-01T00:00:00Z";
  assert.throws(() => buildEvidenceBundle(overlong), /window_range/);

  const prematureExport = input();
  prematureExport.sourceArtifacts[0].exportedAt = "2026-08-27T23:59:59Z";
  assert.throws(() => buildEvidenceBundle(prematureExport), /source_artifact_chronology/);
});

test("CLI commits canonical evidence once and refuses to overwrite it", async () => {
  const directory = await mkdtemp(join(tmpdir(), "mindbudget-c5-evidence-"));
  const inputPath = join(directory, "input.json");
  const outputPath = join(directory, "output.json");
  await writeFile(inputPath, JSON.stringify(input()), "utf8");
  const argumentsList = [
    "tools/build-c5-evidence.mjs",
    "--input",
    inputPath,
    "--output",
    outputPath,
  ];

  const first = spawnSync(process.execPath, argumentsList, { cwd: new URL("..", import.meta.url) });
  assert.equal(first.status, 0, first.stderr.toString());
  const accepted = await readFile(outputPath, "utf8");
  assert.equal(accepted, canonicalEvidenceJSON(buildEvidenceBundle(input())));

  const second = spawnSync(process.execPath, argumentsList, { cwd: new URL("..", import.meta.url) });
  assert.notEqual(second.status, 0);
  assert.equal(await readFile(outputPath, "utf8"), accepted);
});
