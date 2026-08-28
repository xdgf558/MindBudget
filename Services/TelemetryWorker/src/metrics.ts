const APP_VERSION_PATTERN = /^[0-9]+(?:\.[0-9]+)*$/;
const MAXIMUM_OBSERVATION_WINDOW_MILLISECONDS = 90 * 24 * 60 * 60 * 1000;

export interface ReceiptFunnelScope {
  readonly appVersion: string;
  readonly startMilliseconds: number;
  readonly endMilliseconds: number;
}

export interface ReceiptFunnelCounts {
  readonly openedGenerations: number;
  readonly acquiredGenerations: number;
  readonly reviewedGenerations: number;
  readonly savedGenerations: number;
}

function validatedReceiptFunnelScope(scope: ReceiptFunnelScope): ReceiptFunnelScope {
  if (
    !APP_VERSION_PATTERN.test(scope.appVersion)
    || scope.appVersion.length > 32
    || !Number.isSafeInteger(scope.startMilliseconds)
    || !Number.isSafeInteger(scope.endMilliseconds)
    || scope.startMilliseconds < 0
    || scope.endMilliseconds <= scope.startMilliseconds
    || scope.endMilliseconds - scope.startMilliseconds > MAXIMUM_OBSERVATION_WINDOW_MILLISECONDS
  ) {
    throw new Error("invalid_receipt_funnel_scope");
  }
  return scope;
}

/**
 * Returns only aggregate counts. A funnel member is one telemetry pseudonym generation, not a
 * person, device, or durable customer identity. Every later stage must have an ordered completed
 * predecessor inside the same app-version/window cohort. No identifier or event row leaves D1.
 */
export async function receiptFunnelCounts(
  database: D1Database,
  uncheckedScope: ReceiptFunnelScope,
): Promise<ReceiptFunnelCounts> {
  const scope = validatedReceiptFunnelScope(uncheckedScope);
  const row = await database.prepare(
    `WITH scoped AS (
       SELECT pseudonymous_id, occurred_at_ms, action
       FROM telemetry_events
       WHERE event_name = 'receipt_flow'
         AND outcome = 'completed'
         AND app_version = ?1
         AND occurred_at_ms >= ?2
         AND occurred_at_ms < ?3
     ),
     opened AS (
       SELECT pseudonymous_id, MIN(occurred_at_ms) AS opened_at
       FROM scoped
       WHERE action = 'opened'
       GROUP BY pseudonymous_id
     ),
     acquired AS (
       SELECT candidate.pseudonymous_id, MIN(candidate.occurred_at_ms) AS acquired_at
       FROM scoped AS candidate
       JOIN opened ON opened.pseudonymous_id = candidate.pseudonymous_id
       WHERE candidate.action = 'acquired'
         AND candidate.occurred_at_ms >= opened.opened_at
       GROUP BY candidate.pseudonymous_id
     ),
     reviewed AS (
       SELECT candidate.pseudonymous_id, MIN(candidate.occurred_at_ms) AS reviewed_at
       FROM scoped AS candidate
       JOIN acquired ON acquired.pseudonymous_id = candidate.pseudonymous_id
       WHERE candidate.action = 'reviewed'
         AND candidate.occurred_at_ms >= acquired.acquired_at
       GROUP BY candidate.pseudonymous_id
     ),
     saved AS (
       SELECT candidate.pseudonymous_id, MIN(candidate.occurred_at_ms) AS saved_at
       FROM scoped AS candidate
       JOIN reviewed ON reviewed.pseudonymous_id = candidate.pseudonymous_id
       WHERE candidate.action = 'saved'
         AND candidate.occurred_at_ms >= reviewed.reviewed_at
       GROUP BY candidate.pseudonymous_id
     )
     SELECT
       (SELECT COUNT(*) FROM opened) AS opened_generations,
       (SELECT COUNT(*) FROM acquired) AS acquired_generations,
       (SELECT COUNT(*) FROM reviewed) AS reviewed_generations,
       (SELECT COUNT(*) FROM saved) AS saved_generations`,
  ).bind(
    scope.appVersion,
    scope.startMilliseconds,
    scope.endMilliseconds,
  ).first<{
    opened_generations: number;
    acquired_generations: number;
    reviewed_generations: number;
    saved_generations: number;
  }>();

  if (row === null) throw new Error("receipt_funnel_query_failed");
  const result = {
    openedGenerations: row.opened_generations,
    acquiredGenerations: row.acquired_generations,
    reviewedGenerations: row.reviewed_generations,
    savedGenerations: row.saved_generations,
  };
  if (
    !Object.values(result).every(Number.isSafeInteger)
    || result.openedGenerations < result.acquiredGenerations
    || result.acquiredGenerations < result.reviewedGenerations
    || result.reviewedGenerations < result.savedGenerations
    || result.savedGenerations < 0
  ) {
    throw new Error("invalid_receipt_funnel_result");
  }
  return result;
}
