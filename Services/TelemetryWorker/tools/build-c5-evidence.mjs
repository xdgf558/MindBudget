import { link, readFile, stat, unlink, writeFile } from "node:fs/promises";
import { basename, dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const MAXIMUM_INPUT_BYTES = 512 * 1024;
const MAXIMUM_SEGMENTS = 64;
const MAXIMUM_SOURCE_ARTIFACTS = 192;
const EVIDENCE_VERSION = "c5-03-v1";
const Z95 = 1.959963984540054;
const BASIS_POINTS = 10_000;
const TIMESTAMP_PATTERN = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/;
const APP_VERSION_PATTERN = /^[0-9]+(?:\.[0-9]+)*$/;
const STOREFRONT_PATTERN = /^(?:ALL|[A-Z]{3})$/;
const SHA256_PATTERN = /^[0-9a-f]{64}$/;

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

const requiredMetricIDs = Object.freeze(Object.keys(metricSources));
const acceptedStatuses = new Set(["available", "not_collected", "source_suppressed", "zero_denominator"]);
const acceptedEnvironments = new Set(["development", "staging", "production"]);
const acceptedDeviceFamilies = new Set(["all", "iPhone", "iPad"]);
const acceptedArtifactKinds = new Set(Object.values(metricSources));

function fail(reason) {
  throw new Error(`invalid_c5_evidence:${reason}`);
}

function exactObject(value, keys, reason) {
  if (value === null || Array.isArray(value) || typeof value !== "object") fail(reason);
  const actual = Object.keys(value).sort();
  const expected = [...keys].sort();
  if (actual.length !== expected.length || actual.some((key, index) => key !== expected[index])) {
    fail(reason);
  }
  return value;
}

function strictDate(value, reason) {
  if (typeof value !== "string" || !TIMESTAMP_PATTERN.test(value)) fail(reason);
  const milliseconds = Date.parse(value);
  if (!Number.isFinite(milliseconds) || new Date(milliseconds).toISOString() !== value.replace("Z", ".000Z")) {
    fail(reason);
  }
  return milliseconds;
}

function safeCount(value, reason) {
  if (!Number.isSafeInteger(value) || value < 0) fail(reason);
  return value;
}

export function wilson95BasisPoints(numerator, denominator) {
  safeCount(numerator, "confidence_numerator");
  safeCount(denominator, "confidence_denominator");
  if (denominator === 0 || numerator > denominator) fail("confidence_fraction");
  const proportion = numerator / denominator;
  const zSquared = Z95 * Z95;
  const denominatorAdjustment = 1 + zSquared / denominator;
  const center = (proportion + zSquared / (2 * denominator)) / denominatorAdjustment;
  const margin = Z95 * Math.sqrt(
    (proportion * (1 - proportion) + zSquared / (4 * denominator)) / denominator,
  ) / denominatorAdjustment;
  return Object.freeze({
    estimateBasisPoints: Math.round(proportion * BASIS_POINTS),
    lowerBasisPoints: Math.max(0, Math.floor((center - margin) * BASIS_POINTS)),
    upperBasisPoints: Math.min(BASIS_POINTS, Math.ceil((center + margin) * BASIS_POINTS)),
  });
}

function validatedArtifact(value) {
  const artifact = exactObject(value, ["exportedAt", "kind", "sha256"], "source_artifact_shape");
  if (!acceptedArtifactKinds.has(artifact.kind)) fail("source_artifact_kind");
  if (typeof artifact.sha256 !== "string" || !SHA256_PATTERN.test(artifact.sha256)) {
    fail("source_artifact_digest");
  }
  strictDate(artifact.exportedAt, "source_artifact_date");
  return Object.freeze({
    exportedAt: artifact.exportedAt,
    kind: artifact.kind,
    sha256: artifact.sha256,
  });
}

function validatedMetric(value, artifactByDigest) {
  const metric = exactObject(
    value,
    ["artifactSHA256", "denominator", "id", "numerator", "sampleSize", "source", "status"],
    "metric_shape",
  );
  if (!Object.hasOwn(metricSources, metric.id) || metric.source !== metricSources[metric.id]) {
    fail("metric_identity");
  }
  if (!acceptedStatuses.has(metric.status)) fail("metric_status");

  if (metric.status === "available") {
    const numerator = safeCount(metric.numerator, "metric_numerator");
    const denominator = safeCount(metric.denominator, "metric_denominator");
    const sampleSize = safeCount(metric.sampleSize, "metric_sample_size");
    if (denominator === 0 || numerator > denominator || sampleSize < denominator) {
      fail("metric_fraction");
    }
    if (typeof metric.artifactSHA256 !== "string" || !artifactByDigest.has(metric.artifactSHA256)) {
      fail("metric_artifact");
    }
    if (artifactByDigest.get(metric.artifactSHA256).kind !== metric.source) {
      fail("metric_artifact_source");
    }
    const confidence = wilson95BasisPoints(numerator, denominator);
    return Object.freeze({
      artifactSHA256: metric.artifactSHA256,
      confidenceInterval95: Object.freeze({
        lowerBasisPoints: confidence.lowerBasisPoints,
        upperBasisPoints: confidence.upperBasisPoints,
      }),
      denominator,
      estimateBasisPoints: confidence.estimateBasisPoints,
      id: metric.id,
      numerator,
      sampleSize,
      source: metric.source,
      status: metric.status,
    });
  }

  if (metric.status === "zero_denominator") {
    if (metric.numerator !== 0 || metric.denominator !== 0 || metric.sampleSize !== 0) {
      fail("zero_denominator_counts");
    }
    if (typeof metric.artifactSHA256 !== "string" || !artifactByDigest.has(metric.artifactSHA256)) {
      fail("zero_denominator_artifact");
    }
    if (artifactByDigest.get(metric.artifactSHA256).kind !== metric.source) {
      fail("zero_denominator_artifact_source");
    }
  } else if (metric.status === "source_suppressed") {
    if (metric.numerator !== null || metric.denominator !== null || metric.sampleSize !== null) {
      fail("suppressed_counts");
    }
    if (typeof metric.artifactSHA256 !== "string" || !artifactByDigest.has(metric.artifactSHA256)) {
      fail("suppressed_artifact");
    }
    if (artifactByDigest.get(metric.artifactSHA256).kind !== metric.source) {
      fail("suppressed_artifact_source");
    }
  } else if (
    metric.numerator !== null
    || metric.denominator !== null
    || metric.sampleSize !== null
    || metric.artifactSHA256 !== null
  ) {
    fail("not_collected_values");
  }

  return Object.freeze({
    artifactSHA256: metric.artifactSHA256,
    confidenceInterval95: null,
    denominator: metric.denominator,
    estimateBasisPoints: null,
    id: metric.id,
    numerator: metric.numerator,
    sampleSize: metric.sampleSize,
    source: metric.source,
    status: metric.status,
  });
}

function validatedSegment(value, artifactByDigest, evaluatedAppVersion) {
  const segment = exactObject(
    value,
    ["appVersion", "deviceFamily", "environment", "metrics", "storefront"],
    "segment_shape",
  );
  if (!acceptedEnvironments.has(segment.environment)) fail("segment_environment");
  if (segment.appVersion !== evaluatedAppVersion) fail("segment_app_version");
  if (!acceptedDeviceFamilies.has(segment.deviceFamily)) fail("segment_device_family");
  if (typeof segment.storefront !== "string" || !STOREFRONT_PATTERN.test(segment.storefront)) {
    fail("segment_storefront");
  }
  if (!Array.isArray(segment.metrics) || segment.metrics.length !== requiredMetricIDs.length) {
    fail("segment_metric_count");
  }
  const metrics = segment.metrics.map((metric) => validatedMetric(metric, artifactByDigest));
  const metricIDs = metrics.map((metric) => metric.id);
  if (new Set(metricIDs).size !== requiredMetricIDs.length) fail("duplicate_metric");
  if (requiredMetricIDs.some((identifier) => !metricIDs.includes(identifier))) fail("missing_metric");
  metrics.sort((lhs, rhs) => lhs.id.localeCompare(rhs.id, "en"));

  const availableMetrics = metrics.filter((metric) => metric.status === "available");
  const availableMetricCount = availableMetrics.length;
  const evidenceBearingMetricCount = metrics.filter((metric) => metric.status !== "not_collected").length;
  const widestConfidenceIntervalBasisPoints = availableMetrics.length === 0
    ? null
    : Math.max(...availableMetrics.map((metric) => (
      metric.confidenceInterval95.upperBasisPoints - metric.confidenceInterval95.lowerBasisPoints
    )));
  return Object.freeze({
    appVersion: segment.appVersion,
    coverage: Object.freeze({
      availableMetricCount,
      availableRatioBasisPoints: Math.floor(availableMetricCount * BASIS_POINTS / requiredMetricIDs.length),
      evidenceBearingMetricCount,
      evidenceBearingRatioBasisPoints: Math.floor(
        evidenceBearingMetricCount * BASIS_POINTS / requiredMetricIDs.length,
      ),
      requiredMetricCount: requiredMetricIDs.length,
      widestConfidenceIntervalBasisPoints,
    }),
    deviceFamily: segment.deviceFamily,
    environment: segment.environment,
    metrics,
    storefront: segment.storefront,
  });
}

export function buildEvidenceBundle(value) {
  const input = exactObject(
    value,
    ["evaluatedAppVersion", "evidenceVersion", "generatedAt", "observationWindow", "schemaVersion", "segments", "sourceArtifacts", "telemetrySchemaVersion"],
    "root_shape",
  );
  if (input.schemaVersion !== 1 || input.evidenceVersion !== EVIDENCE_VERSION) fail("version");
  if (
    typeof input.evaluatedAppVersion !== "string"
    || input.evaluatedAppVersion.length > 32
    || !APP_VERSION_PATTERN.test(input.evaluatedAppVersion)
  ) fail("evaluated_app_version");
  if (input.telemetrySchemaVersion !== 1) fail("telemetry_schema_version");
  const generatedAt = strictDate(input.generatedAt, "generated_at");
  const observation = exactObject(input.observationWindow, ["end", "start"], "window_shape");
  const start = strictDate(observation.start, "window_start");
  const end = strictDate(observation.end, "window_end");
  if (start >= end || generatedAt < end || end - start > 90 * 24 * 60 * 60 * 1000) {
    fail("window_range");
  }
  if (
    !Array.isArray(input.sourceArtifacts)
    || input.sourceArtifacts.length > MAXIMUM_SOURCE_ARTIFACTS
  ) fail("source_artifact_count");
  const sourceArtifacts = input.sourceArtifacts.map(validatedArtifact);
  for (const artifact of sourceArtifacts) {
    const exportedAt = strictDate(artifact.exportedAt, "source_artifact_date");
    if (exportedAt < end || exportedAt > generatedAt) fail("source_artifact_chronology");
  }
  const artifactByDigest = new Map(sourceArtifacts.map((artifact) => [artifact.sha256, artifact]));
  if (artifactByDigest.size !== sourceArtifacts.length) fail("duplicate_source_artifact");
  sourceArtifacts.sort((lhs, rhs) => lhs.sha256.localeCompare(rhs.sha256, "en"));

  if (!Array.isArray(input.segments) || input.segments.length === 0 || input.segments.length > MAXIMUM_SEGMENTS) {
    fail("segment_count");
  }
  const segments = input.segments.map((segment) => (
    validatedSegment(segment, artifactByDigest, input.evaluatedAppVersion)
  ));
  const segmentKeys = segments.map((segment) => (
    [segment.environment, segment.appVersion, segment.storefront, segment.deviceFamily].join("/")
  ));
  if (new Set(segmentKeys).size !== segmentKeys.length) fail("duplicate_segment");
  segments.sort((lhs, rhs) => (
    [lhs.environment, lhs.appVersion, lhs.storefront, lhs.deviceFamily].join("/")
      .localeCompare([rhs.environment, rhs.appVersion, rhs.storefront, rhs.deviceFamily].join("/"), "en")
  ));

  return Object.freeze({
    confidenceMethod: "wilson_score_95_outward_rounded_basis_points",
    evaluatedAppVersion: input.evaluatedAppVersion,
    evidenceVersion: EVIDENCE_VERSION,
    generatedAt: input.generatedAt,
    observationWindow: Object.freeze({ end: observation.end, start: observation.start }),
    schemaVersion: 1,
    segments,
    sourceArtifacts,
    telemetrySchemaVersion: 1,
  });
}

function canonicalValue(value) {
  if (Array.isArray(value)) return value.map(canonicalValue);
  if (value !== null && typeof value === "object") {
    return Object.fromEntries(
      Object.keys(value).sort().map((key) => [key, canonicalValue(value[key])]),
    );
  }
  return value;
}

export function canonicalEvidenceJSON(value) {
  return `${JSON.stringify(canonicalValue(value), null, 2)}\n`;
}

async function main(argumentsList) {
  if (argumentsList.length !== 4 || argumentsList[0] !== "--input" || argumentsList[2] !== "--output") {
    throw new Error("usage: npm run evidence:build -- --input INPUT.json --output OUTPUT.json");
  }
  const inputPath = resolve(argumentsList[1]);
  const outputPath = resolve(argumentsList[3]);
  if (inputPath === outputPath) throw new Error("input and output paths must differ");
  const inputStat = await stat(inputPath);
  if (!inputStat.isFile() || inputStat.size === 0 || inputStat.size > MAXIMUM_INPUT_BYTES) {
    throw new Error("evidence input must be a non-empty file no larger than 512 KiB");
  }
  const input = JSON.parse(await readFile(inputPath, "utf8"));
  const output = canonicalEvidenceJSON(buildEvidenceBundle(input));
  const temporaryPath = resolve(dirname(outputPath), `.${basename(outputPath)}.${process.pid}.tmp`);
  try {
    await writeFile(temporaryPath, output, { encoding: "utf8", flag: "wx", mode: 0o600 });
    // An immutable evidence path must never be silently replaced. A same-directory hard link is
    // the atomic commit point and fails when the requested output already exists.
    await link(temporaryPath, outputPath);
    await unlink(temporaryPath);
    if (await readFile(outputPath, "utf8") !== output) throw new Error("evidence read-back failed");
  } catch (error) {
    await unlink(temporaryPath).catch(() => undefined);
    throw error;
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main(process.argv.slice(2)).catch((error) => {
    console.error(error instanceof Error ? error.message : "evidence build failed");
    process.exitCode = 1;
  });
}
