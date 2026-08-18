#!/usr/bin/env python3
"""Unit tests for the MindBudgetTheme colour-token parser."""

import sys
import unittest
from pathlib import Path

SCRIPTS_DIRECTORY = Path(__file__).resolve().parents[1]
PROJECT_ROOT = SCRIPTS_DIRECTORY.parent
sys.path.insert(0, str(SCRIPTS_DIRECTORY))

from theme_palette import (  # noqa: E402
    CHART_TOKEN,
    ThemeParseError,
    contrast_ratio,
    parse_skins,
    parse_theme,
    render,
    resolve,
    wcag_grade,
)

THEME_SOURCE = PROJECT_ROOT / "MindBudget" / "Features" / "Shared" / "AppTheme.swift"


SKIN_ENUM_FIXTURE = """enum AppSkin: String, CaseIterable {
    case auroraGlow
    case warmBotanical
    case neonPulse
}
"""


def theme_fragment(body, skins=SKIN_ENUM_FIXTURE):
    return skins + "\nstruct MindBudgetTheme {\n" + body + "\n}\n"


class ResolveTests(unittest.TestCase):
    def test_reads_a_plain_colour(self):
        self.assertEqual(
            resolve("Color(red: 0.25, green: 0.50, blue: 0.75)"), [0.25, 0.5, 0.75]
        )

    def test_named_colour_with_opacity_keeps_alpha(self):
        self.assertEqual(resolve("Color.white.opacity(0.04)"), [1.0, 1.0, 1.0, 0.04])

    def test_alias_resolves_through_an_earlier_token(self):
        known = {"accent": {"neonPulse": [0.6, 0.35, 1.0]}}
        self.assertEqual(resolve("accent", "neonPulse", known), [0.6, 0.35, 1.0])

    def test_alias_keeps_the_referenced_alpha(self):
        """A dropped alpha renders a translucent colour as opaque — silently wrong."""
        known = {"scrim": {"warmBotanical": [1.0, 1.0, 1.0, 0.04]}}
        self.assertEqual(
            resolve("scrim", "warmBotanical", known), [1.0, 1.0, 1.0, 0.04]
        )

    def test_stacked_opacity_multiplies_like_swiftui(self):
        known = {"scrim": {"warmBotanical": [1.0, 1.0, 1.0, 0.5]}}
        self.assertEqual(
            resolve("scrim.opacity(0.5)", "warmBotanical", known),
            [1.0, 1.0, 1.0, 0.25],
        )

    def test_alias_with_opacity_keeps_the_base_colour(self):
        known = {"attention": {"auroraGlow": [0.92, 0.71, 0.35]}}
        self.assertEqual(
            resolve("attention.opacity(0.52)", "auroraGlow", known),
            [0.92, 0.71, 0.35, 0.52],
        )

    def test_unknown_expression_is_rejected(self):
        self.assertIsNone(resolve("someUndefinedToken", "neonPulse", {}))


class ParseTests(unittest.TestCase):
    def test_per_skin_switch(self):
        theme = parse_theme(
            theme_fragment(
                """
    var canvas: Color {
        switch skin {
        case .auroraGlow: Color(red: 0.0, green: 0.1, blue: 0.2)
        case .warmBotanical: Color(red: 0.9, green: 0.9, blue: 0.8)
        case .neonPulse: Color(red: 0.0, green: 0.0, blue: 0.1)
        }
    }
"""
            )
        )
        self.assertEqual(theme["tokens"]["canvas"]["warmBotanical"], [0.9, 0.9, 0.8])

    def test_ternary_branches_survive_colons_inside_colour_calls(self):
        """Regression: splitting the ternary on ':' broke on Color(red:green:blue:)."""
        theme = parse_theme(
            theme_fragment(
                """
    var accent: Color {
        switch skin {
        case .auroraGlow: Color(red: 0.4, green: 0.9, blue: 0.8)
        case .warmBotanical: Color(red: 0.4, green: 0.6, blue: 0.4)
        case .neonPulse: Color(red: 0.6, green: 0.3, blue: 1.0)
        }
    }
    var attentionText: Color { skin == .warmBotanical ? Color(red: 0.49, green: 0.33, blue: 0.12) : accent }
"""
            )
        )
        self.assertEqual(
            theme["tokens"]["attentionText"]["warmBotanical"], [0.49, 0.33, 0.12]
        )
        self.assertEqual(theme["tokens"]["attentionText"]["neonPulse"], [0.6, 0.3, 1.0])

    def test_alias_may_be_declared_before_the_token_it_references(self):
        theme = parse_theme(
            theme_fragment(
                """
    var dark: Color { skin == .warmBotanical ? Color(red: 0.1, green: 0.1, blue: 0.1) : canvas }
    var canvas: Color {
        switch skin {
        case .auroraGlow: Color(red: 0.0, green: 0.1, blue: 0.2)
        case .warmBotanical: Color(red: 0.9, green: 0.9, blue: 0.8)
        case .neonPulse: Color(red: 0.0, green: 0.0, blue: 0.1)
        }
    }
"""
            )
        )
        self.assertEqual(theme["tokens"]["dark"]["neonPulse"], [0.0, 0.0, 0.1])

    def test_skins_come_from_the_enum_not_a_constant(self):
        """A fourth skin must widen the sheet, never be silently ignored."""
        four = SKIN_ENUM_FIXTURE.replace(
            "    case neonPulse\n", "    case neonPulse\n    case midnightSun\n"
        )
        self.assertIn("midnightSun", parse_skins(four))
        with self.assertRaises(ThemeParseError):
            parse_theme(
                theme_fragment(
                    """
    var canvas: Color {
        switch skin {
        case .auroraGlow: Color(red: 0.0, green: 0.1, blue: 0.2)
        case .warmBotanical: Color(red: 0.9, green: 0.9, blue: 0.8)
        case .neonPulse: Color(red: 0.0, green: 0.0, blue: 0.1)
        }
    }
""",
                    skins=four,
                )
            )

    def test_layout_change_that_finds_nothing_fails(self):
        """A reformat to two-space indent must not quietly yield an empty sheet."""
        with self.assertRaises(ThemeParseError):
            parse_theme(
                theme_fragment(
                    "  var canvas: Color { Color(red: 0.1, green: 0.1, blue: 0.1) }"
                )
            )

    def test_unresolvable_token_fails_loudly(self):
        with self.assertRaises(ThemeParseError):
            parse_theme(
                theme_fragment(
                    "    var mystery: Color { skin == .neonPulse ? unknownA : unknownB }"
                )
            )


class ContrastTests(unittest.TestCase):
    def test_translucent_input_is_rejected_rather_than_miscomputed(self):
        with self.assertRaises(ThemeParseError):
            contrast_ratio([1.0, 1.0, 1.0, 0.04], [1.0, 1.0, 1.0])

    def test_black_on_white_is_the_maximum_ratio(self):
        self.assertAlmostEqual(contrast_ratio([0, 0, 0], [1, 1, 1]), 21.0, places=2)

    def test_identical_colours_have_no_contrast(self):
        self.assertAlmostEqual(contrast_ratio([0.3, 0.4, 0.5], [0.3, 0.4, 0.5]), 1.0)

    def test_grades_follow_the_wcag_thresholds(self):
        self.assertEqual(wcag_grade(7.0)[0], "AAA")
        self.assertEqual(wcag_grade(4.5)[0], "AA")
        self.assertEqual(wcag_grade(3.0)[0], "AA Large")
        self.assertEqual(wcag_grade(2.9)[0], "Fail")


class ShippingThemeTests(unittest.TestCase):
    """The parser has to keep working against the real theme, not only fixtures."""

    @classmethod
    def setUpClass(cls):
        cls.theme = parse_theme(THEME_SOURCE.read_text(encoding="utf-8"))

    def test_every_token_resolves_for_every_skin(self):
        for name in self.theme["order"]:
            self.assertEqual(
                sorted(self.theme["tokens"][name]),
                sorted(self.theme["skins"]),
                "token %s" % name,
            )

    def test_chart_scale_covers_the_maximum_segment_count(self):
        scale = self.theme["scales"][CHART_TOKEN]
        for skin in self.theme["skins"]:
            self.assertEqual(len(scale[skin]), 6, "chart scale for %s" % skin)

    def test_chart_colours_are_distinct_within_a_skin(self):
        scale = self.theme["scales"][CHART_TOKEN]
        for skin in self.theme["skins"]:
            values = [tuple(color) for color in scale[skin]]
            self.assertEqual(len(set(values)), len(values), "duplicate in %s" % skin)

    def test_foundational_tokens_are_present(self):
        for name in ["canvas", "surface", "ink", "accent"]:
            self.assertIn(name, self.theme["tokens"])

    def test_skins_match_the_enum(self):
        source = THEME_SOURCE.read_text(encoding="utf-8")
        self.assertEqual(sorted(self.theme["skins"]), sorted(parse_skins(source)))

    def test_contrast_tokens_are_opaque(self):
        """Contrast maths cannot composite, so its inputs must carry no alpha."""
        from theme_palette import TEXT_TOKENS

        for name in TEXT_TOKENS:
            for skin in self.theme["skins"]:
                self.assertEqual(len(self.theme["tokens"][name][skin]), 3, name)
                self.assertEqual(len(self.theme["tokens"]["surface"][skin]), 3)

    def test_rendered_document_is_standards_mode(self):
        html = render(self.theme)
        self.assertTrue(html.startswith("<!DOCTYPE html>"))
        self.assertIn("<html", html)
        self.assertIn("</body></html>", html)


if __name__ == "__main__":
    unittest.main(verbosity=2)
