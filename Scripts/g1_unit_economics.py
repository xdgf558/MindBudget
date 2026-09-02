#!/usr/bin/env python3
"""Deterministic G1 quote-envelope arithmetic using integer micro-USD only."""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path


MICRO_USD_PER_USD = 1_000_000
TOKENS_PER_QUOTED_UNIT = 1_000_000
BASIS_POINTS_PER_ONE = 10_000


def ceil_div(numerator: int, denominator: int) -> int:
    if numerator < 0 or denominator <= 0:
        raise ValueError("ceil_div accepts a nonnegative numerator and positive denominator")
    return (numerator + denominator - 1) // denominator


def apply_basis_points(amount: int, basis_points: int) -> int:
    return ceil_div(amount * basis_points, BASIS_POINTS_PER_ONE)


@dataclass(frozen=True)
class TokenQuote:
    input_micro_usd_per_million: int
    output_micro_usd_per_million: int

    def cost(self, *, input_tokens: int, output_tokens: int) -> int:
        input_cost = ceil_div(
            input_tokens * self.input_micro_usd_per_million,
            TOKENS_PER_QUOTED_UNIT,
        )
        output_cost = ceil_div(
            output_tokens * self.output_micro_usd_per_million,
            TOKENS_PER_QUOTED_UNIT,
        )
        return input_cost + output_cost


@dataclass(frozen=True)
class Workload:
    input_tokens: int
    output_tokens: int


# Quote date: 2026-09-02, rechecked against the official model page on 2026-09-02.
# These rates are deliberately the non-batch interactive rates. The accepted planning quote
# includes the documented 10% regional-processing uplift.
LUNA_QUOTE = TokenQuote(
    input_micro_usd_per_million=220_000,
    output_micro_usd_per_million=1_320_000,
)

TYPICAL_WORKLOAD = Workload(input_tokens=2_000, output_tokens=500)
PEAK_WORKLOAD = Workload(input_tokens=8_000, output_tokens=1_500)

# This is an engineering reserve, not an observed failure rate.
PROVIDER_SAFETY_RESERVE_BPS = 2_000

# Paid Workers floor plus an equal incident/support reserve, allocated over the accepted
# 1,000-successful-use monthly planning floor. Variable operations use published overage rates
# even though the planning volume remains inside the included allowances.
PLANNING_SUCCESSES_PER_MONTH = 1_000
WORKERS_MONTHLY_FLOOR_MICRO_USD = 5_000_000
INCIDENT_MONTHLY_RESERVE_MICRO_USD = 5_000_000

WORKER_REQUESTS_PER_USE = 1
WORKER_CPU_MS_PER_USE = 20
D1_ROWS_READ_PER_USE = 8
D1_ROWS_WRITTEN_PER_USE = 6
LOG_EVENTS_PER_USE = 1

WORKER_REQUEST_MICRO_USD_PER_MILLION = 300_000
WORKER_CPU_MICRO_USD_PER_MILLION_MS = 20_000
D1_READ_MICRO_USD_PER_MILLION_ROWS = 1_000
D1_WRITE_MICRO_USD_PER_MILLION_ROWS = 1_000_000
LOG_MICRO_USD_PER_MILLION_EVENTS = 600_000

OFFER_GROSS_MICRO_USD = 4_990_000
STANDARD_COMMISSION_BPS = 3_000
TAX_AND_FX_RESERVE_BPS = 1_000
REFUND_RESERVE_BPS = 500
MINIMUM_CONTRIBUTION_MARGIN_BPS = 5_000
PEAK_LUNA_ATTEMPTS = 2

STARTER_CANDIDATES = (5, 10, 15)
ACCEPTED_STARTER_USES = 10
ACCEPTED_CARD_OFFERS = (
    (990_000, 10),
    (1_990_000, 25),
    (4_990_000, 65),
)


def variable_backend_cost_per_use() -> int:
    return sum(
        (
            ceil_div(
                WORKER_REQUESTS_PER_USE * WORKER_REQUEST_MICRO_USD_PER_MILLION,
                1_000_000,
            ),
            ceil_div(
                WORKER_CPU_MS_PER_USE * WORKER_CPU_MICRO_USD_PER_MILLION_MS,
                1_000_000,
            ),
            ceil_div(
                D1_ROWS_READ_PER_USE * D1_READ_MICRO_USD_PER_MILLION_ROWS,
                1_000_000,
            ),
            ceil_div(
                D1_ROWS_WRITTEN_PER_USE * D1_WRITE_MICRO_USD_PER_MILLION_ROWS,
                1_000_000,
            ),
            ceil_div(
                LOG_EVENTS_PER_USE * LOG_MICRO_USD_PER_MILLION_EVENTS,
                1_000_000,
            ),
        )
    )


def backend_cost_per_use(monthly_successes: int) -> int:
    if monthly_successes <= 0:
        raise ValueError("monthly_successes must be positive")
    fixed = ceil_div(
        WORKERS_MONTHLY_FLOOR_MICRO_USD + INCIDENT_MONTHLY_RESERVE_MICRO_USD,
        monthly_successes,
    )
    return fixed + variable_backend_cost_per_use()


def provider_cost_with_reserve(amount: int) -> int:
    return amount + apply_basis_points(amount, PROVIDER_SAFETY_RESERVE_BPS)


def unit_costs(monthly_successes: int = PLANNING_SUCCESSES_PER_MONTH) -> dict[str, int]:
    typical_provider = LUNA_QUOTE.cost(
        input_tokens=TYPICAL_WORKLOAD.input_tokens,
        output_tokens=TYPICAL_WORKLOAD.output_tokens,
    )
    peak_luna_per_attempt = LUNA_QUOTE.cost(
        input_tokens=PEAK_WORKLOAD.input_tokens,
        output_tokens=PEAK_WORKLOAD.output_tokens,
    )
    peak_luna = peak_luna_per_attempt * PEAK_LUNA_ATTEMPTS
    backend = backend_cost_per_use(monthly_successes)
    return {
        "typical_provider": typical_provider,
        "peak_luna_per_attempt": peak_luna_per_attempt,
        "peak_luna_attempts": PEAK_LUNA_ATTEMPTS,
        "peak_luna": peak_luna,
        "backend": backend,
        "typical_all_in": provider_cost_with_reserve(typical_provider) + backend,
        "peak_all_in": provider_cost_with_reserve(peak_luna) + backend,
    }


def conservative_net_proceeds(gross_micro_usd: int) -> int:
    deductions = (
        apply_basis_points(gross_micro_usd, STANDARD_COMMISSION_BPS)
        + apply_basis_points(gross_micro_usd, TAX_AND_FX_RESERVE_BPS)
        + apply_basis_points(gross_micro_usd, REFUND_RESERVE_BPS)
    )
    return gross_micro_usd - deductions


def build_report() -> dict[str, object]:
    costs = unit_costs()
    offer_net = conservative_net_proceeds(OFFER_GROSS_MICRO_USD)
    maximum_fulfillment_cost = offer_net - apply_basis_points(
        offer_net, MINIMUM_CONTRIBUTION_MARGIN_BPS
    )

    starter_rows = []
    for count in STARTER_CANDIDATES:
        typical_cost = count * costs["typical_all_in"]
        peak_cost = count * costs["peak_all_in"]
        starter_rows.append(
            {
                "uses": count,
                "typical_cost": typical_cost,
                "peak_cost": peak_cost,
                "peak_contribution": offer_net - peak_cost,
                "peak_margin_bps": (offer_net - peak_cost) * BASIS_POINTS_PER_ONE // offer_net,
                "passes_minimum_margin": peak_cost <= maximum_fulfillment_cost,
            }
        )

    card_rows = []
    for gross, count in ACCEPTED_CARD_OFFERS:
        net = conservative_net_proceeds(gross)
        typical_cost = count * costs["typical_all_in"]
        peak_cost = count * costs["peak_all_in"]
        contribution = net - peak_cost
        margin_bps = contribution * BASIS_POINTS_PER_ONE // net
        card_rows.append(
            {
                "gross": gross,
                "uses": count,
                "customer_price_per_use": gross // count,
                "net_proceeds": net,
                "typical_cost": typical_cost,
                "peak_cost": peak_cost,
                "peak_contribution": contribution,
                "peak_margin_bps": margin_bps,
                "passes_minimum_margin": margin_bps >= MINIMUM_CONTRIBUTION_MARGIN_BPS,
            }
        )

    scale_rows = []
    for monthly_successes in (100, 500, 1_000, 10_000):
        scale_costs = unit_costs(monthly_successes)
        scale_rows.append(
            {
                "monthly_successes": monthly_successes,
                "typical_all_in": scale_costs["typical_all_in"],
                "peak_all_in": scale_costs["peak_all_in"],
            }
        )

    return {
        "unit_costs": costs,
        "offer": {
            "gross": OFFER_GROSS_MICRO_USD,
            "net_after_store_tax_refund_reserves": offer_net,
            "minimum_contribution_margin_bps": MINIMUM_CONTRIBUTION_MARGIN_BPS,
            "maximum_fulfillment_cost_at_margin_floor": maximum_fulfillment_cost,
            "maximum_typical_uses": maximum_fulfillment_cost // costs["typical_all_in"],
            "maximum_peak_uses": maximum_fulfillment_cost // costs["peak_all_in"],
        },
        "starter_candidates": starter_rows,
        "accepted_starter": next(
            row for row in starter_rows if row["uses"] == ACCEPTED_STARTER_USES
        ),
        "accepted_cards": card_rows,
        "server_breaker": {
            "minimum_trailing_30_day_successes": PLANNING_SUCCESSES_PER_MONTH,
            "minimum_peak_margin_bps": MINIMUM_CONTRIBUTION_MARGIN_BPS,
            "action_below_gate": "disable_new_card_sales_and_new_starter_grants",
            "honor_existing_unexpired_credits": True,
        },
        "scale_sensitivity": scale_rows,
    }


EXPECTED_DOC_ANCHORS = (
    "US$0.011330",
    "US$0.018986",
    "US$1.372250",
    "maximum of 72 peak-envelope starter uses",
    "10 starter uses",
    "10 uses / US$0.99",
    "25 uses / US$1.99",
    "65 uses / US$4.99",
    "65.13%",
    "56.63%",
    "55.03%",
    "ACCOUNT_ADMISSION_AND_LIVE_EVAL_BLOCKED",
)


def require_equal(actual: object, expected: object, label: str) -> None:
    if actual != expected:
        raise RuntimeError(f"{label}: expected {expected!r}, got {actual!r}")


def self_test() -> None:
    report = build_report()
    unit = report["unit_costs"]
    offer = report["offer"]
    require_equal(unit["typical_provider"], 1_100, "typical Luna cost")
    require_equal(unit["peak_luna_per_attempt"], 3_740, "peak Luna attempt cost")
    require_equal(unit["peak_luna_attempts"], 2, "bounded peak Luna attempts")
    require_equal(unit["peak_luna"], 7_480, "peak Luna attempt total")
    require_equal(unit["backend"], 10_010, "planning-floor backend cost")
    require_equal(unit["typical_all_in"], 11_330, "typical all-in cost")
    require_equal(unit["peak_all_in"], 18_986, "peak all-in cost")
    require_equal(
        offer["net_after_store_tax_refund_reserves"],
        2_744_500,
        "conservative offer net",
    )
    require_equal(
        offer["maximum_fulfillment_cost_at_margin_floor"],
        1_372_250,
        "50% margin fulfillment ceiling",
    )
    require_equal(offer["maximum_typical_uses"], 121, "maximum typical uses")
    require_equal(offer["maximum_peak_uses"], 72, "maximum peak uses")
    require_equal(
        [row["passes_minimum_margin"] for row in report["starter_candidates"]],
        [True, True, True],
        "starter margin checks",
    )
    require_equal(
        report["accepted_starter"]["uses"],
        ACCEPTED_STARTER_USES,
        "accepted starter grant",
    )
    require_equal(
        report["accepted_starter"]["peak_margin_bps"],
        9_308,
        "accepted starter peak margin",
    )
    require_equal(
        [row["peak_margin_bps"] for row in report["accepted_cards"]],
        [6513, 5663, 5503],
        "card margins",
    )
    require_equal(
        [row["passes_minimum_margin"] for row in report["accepted_cards"]],
        [True, True, True],
        "card margin checks",
    )
    require_equal(
        [(row["gross"], row["uses"]) for row in report["accepted_cards"]],
        list(ACCEPTED_CARD_OFFERS),
        "accepted card offers",
    )
    require_equal(
        report["server_breaker"]["minimum_trailing_30_day_successes"],
        1_000,
        "server breaker volume floor",
    )
    require_equal(
        report["scale_sensitivity"][0]["peak_all_in"],
        108_986,
        "low-volume peak cost",
    )
    require_equal(
        report["scale_sensitivity"][-1]["peak_all_in"],
        9_986,
        "high-volume peak cost",
    )


def check_document(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    missing = [anchor for anchor in EXPECTED_DOC_ANCHORS if anchor not in text]
    if missing:
        raise SystemExit(f"{path} is missing computed G1 anchors: {missing}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--check-document", type=Path)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
    if args.check_document is not None:
        check_document(args.check_document)
    if args.json or (not args.self_test and args.check_document is None):
        print(json.dumps(build_report(), indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
