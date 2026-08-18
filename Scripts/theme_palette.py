#!/usr/bin/env python3
"""Render a colour-token sheet straight from MindBudgetTheme.

`MindBudget/Features/Shared/AppTheme.swift` is the only source of truth for skin
colours. This parses the token values out of it and renders a review sheet, so
the sheet is regenerated rather than hand-maintained and cannot drift from the
code the way a copied palette would.

Four declaration shapes appear in the theme and all four are resolved:

    switch skin { case .x: Color(red:green:blue:) ... }   per-skin literal
    skin == .x ? Color(...) : accent                      ternary with an alias
    attention.opacity(0.52)                               alias plus opacity
    Color.white.opacity(0.04)                             named colour

The ternary form is why branches are matched as whole expression shapes instead
of splitting on `:` — `Color(red: ...)` contains colons of its own.
"""

import argparse
import json
import re

# Display order for the sheet. The authoritative list is parsed from the AppSkin
# enum; this only decides which column comes first, and any skin missing a label
# still renders under its raw case name.
SKIN_ORDER = ["warmBotanical", "auroraGlow", "neonPulse"]
SKIN_LABELS = {
    "warmBotanical": ("Warm Botanical", "暖植物"),
    "auroraGlow": ("Aurora Glow", "极光"),
    "neonPulse": ("Neon Pulse", "霓虹"),
}
CHART_TOKEN = "categoricalChart"
SKIN_ENUM = re.compile(r"enum AppSkin:[^{]*\{(.*?)\n\}", re.S)
SKIN_CASE = re.compile(r"^\s*case (\w+)\s*$", re.M)

COLOR = re.compile(r"Color\(red:\s*([\d.]+),\s*green:\s*([\d.]+),\s*blue:\s*([\d.]+)\)")
NAMED = {"Color.black": [0.0, 0.0, 0.0], "Color.white": [1.0, 1.0, 1.0]}
OPACITY = r"(?:\.opacity\([\d.]+\))?"
BRANCH = (
    r"(Color\([^)]*\)" + OPACITY
    + r"|Color\.\w+" + OPACITY
    + r"|\w+" + OPACITY + r")"
)


class ThemeParseError(RuntimeError):
    """Raised when a token cannot be resolved for every skin."""


def _rgb(match):
    return [float(match.group(1)), float(match.group(2)), float(match.group(3))]


def resolve(expression, skin=None, known=None):
    """Resolve one colour expression to [r, g, b] or [r, g, b, alpha]."""
    expression = expression.strip()
    alpha = None
    trailing = re.search(r"\.opacity\(([\d.]+)\)\s*$", expression)
    if trailing:
        alpha = float(trailing.group(1))
        expression = expression[: trailing.start()].strip()

    literal = COLOR.fullmatch(expression)
    if literal:
        base = _rgb(literal)
    elif expression in NAMED:
        base = list(NAMED[expression])
    elif known and expression in known and skin in known[expression]:
        # Keep the referenced token's own alpha. Dropping it would render a
        # translucent colour as an opaque one — a silently wrong value, which is
        # worse than a missing one. SwiftUI multiplies stacked opacities, so an
        # alias that also carries .opacity() multiplies rather than replaces.
        base = list(known[expression][skin])
    else:
        return None

    inherited = base[3] if len(base) > 3 else None
    base = base[:3]
    if alpha is None:
        alpha = inherited
    elif inherited is not None:
        alpha = round(alpha * inherited, 6)
    return base + ([alpha] if alpha is not None else [])


def _body(source, name):
    """Return the braced body of `var <name>` and its declared type."""
    header = re.search(
        r"\n    var %s:\s*(\[Color\]|Color)\s*\{" % re.escape(name), source
    )
    if not header:
        return None, None
    start = header.end() - 1
    depth = 0
    for index in range(start, len(source)):
        if source[index] == "{":
            depth += 1
        elif source[index] == "}":
            depth -= 1
            if depth == 0:
                return source[start : index + 1], header.group(1)
    return None, None


def parse_skins(source):
    """Read the skin list from the AppSkin enum.

    Hardcoding it would reintroduce exactly the drift this tool exists to
    prevent: a fourth skin would render a sheet that silently covers three.
    """
    block = SKIN_ENUM.search(source)
    if not block:
        raise ThemeParseError("Could not find the AppSkin enum")
    skins = SKIN_CASE.findall(block.group(1))
    if not skins:
        raise ThemeParseError("AppSkin declared no cases")
    ordered = [s for s in SKIN_ORDER if s in skins]
    return ordered + [s for s in skins if s not in ordered]


def _per_skin(body, known, skins):
    values = {}
    for skin in skins:
        match = re.search(r"case \.%s:\s*" % skin + BRANCH, body)
        if match:
            value = resolve(match.group(1), skin, known)
            if value:
                values[skin] = value
    return values


def _derived(body, known, skins):
    values = {}
    ternary = re.search(
        r"skin == \.(\w+)\s*\?\s*" + BRANCH + r"\s*:\s*" + BRANCH, body, re.S
    )
    if ternary:
        target, when_true, when_false = ternary.groups()
        for skin in skins:
            value = resolve(when_true if skin == target else when_false, skin, known)
            if value:
                values[skin] = value
        return values

    constant = re.search(r"\{\s*" + BRANCH + r"\s*\}", body, re.S)
    if constant:
        for skin in skins:
            value = resolve(constant.group(1), skin, known)
            if value:
                values[skin] = value
    return values


def _scale(body, skins):
    values = {}
    for skin in skins:
        match = re.search(r"case \.%s:\s*\[(.*?)\]" % skin, body, re.S)
        if match:
            values[skin] = [_rgb(color) for color in COLOR.finditer(match.group(1))]
    return values


def parse_theme(source):
    """Return {"order": [...], "tokens": {...}, "scales": {...}}."""
    skins = parse_skins(source)
    declared = re.findall(r"\n    var (\w+):\s*(?:\[Color\]|Color)\s*\{", source)
    tokens, scales, order, bodies = {}, {}, [], {}
    for name in declared:
        body, kind = _body(source, name)
        if body is None:
            continue
        if kind == "[Color]":
            scales[name] = _scale(body, skins)
            continue
        bodies[name] = body
        # A token that resolves for no skin at all must fail rather than vanish:
        # silently dropping it would leave a gap in the sheet with nothing to
        # signal that the theme grew a shape this parser does not understand.
        tokens[name] = _per_skin(body, tokens, skins) or _derived(body, tokens, skins)
        order.append(name)

    # Second pass so an alias may point at a token declared later in the file.
    # Without it, reordering two declarations breaks the sheet for no real reason.
    for name in order:
        if len(tokens[name]) == len(skins):
            continue
        retry = _per_skin(bodies[name], tokens, skins) or _derived(bodies[name], tokens, skins)
        if len(retry) > len(tokens[name]):
            tokens[name] = retry

    if not order:
        raise ThemeParseError(
            "No colour tokens were found. The theme's declaration layout probably "
            "changed; this parser expects `    var <name>: Color {` at four-space indent."
        )

    incomplete = sorted(n for n in order if len(tokens[n]) != len(skins))
    if incomplete:
        raise ThemeParseError(
            "Tokens did not resolve for every skin: "
            + ", ".join(incomplete)
            + ". A token aliasing another one must be declared after it."
        )
    return {"order": order, "tokens": tokens, "scales": scales, "skins": skins}


def css(value):
    red, green, blue = (round(channel * 255) for channel in value[:3])
    if len(value) > 3:
        return "rgba(%d,%d,%d,%s)" % (red, green, blue, value[3])
    return "rgb(%d,%d,%d)" % (red, green, blue)


CHECKER = (
    "background-image:linear-gradient(45deg,#bbb 25%,transparent 25%),"
    "linear-gradient(-45deg,#bbb 25%,transparent 25%),"
    "linear-gradient(45deg,transparent 75%,#bbb 75%),"
    "linear-gradient(-45deg,transparent 75%,#bbb 75%);"
    "background-size:8px 8px;"
    "background-position:0 0,0 4px,4px -4px,-4px 0px;"
)


def swatch(value, size=34):
    """A swatch that stays legible when the colour is translucent.

    A colour with alpha painted straight onto the card can be invisible — white
    at 0.04 is the case in this very theme — which would contradict the point of
    the sheet, so translucent values sit on a checkerboard.
    """
    box = "width:%dpx;height:%dpx" % (size, size)
    if len(value) > 3:
        return (
            '<div class="sw" style="%s;%s"><div style="width:100%%;height:100%%;'
            'border-radius:7px;background:%s"></div></div>' % (box, CHECKER, css(value))
        )
    return '<div class="sw" style="%s;background:%s"></div>' % (box, css(value))


def swatch_label(value):
    text = "#" + "".join("%02X" % round(channel * 255) for channel in value[:3])
    return text + (" · α%s" % value[3] if len(value) > 3 else "")


def relative_luminance(value):
    def channel(component):
        if component <= 0.03928:
            return component / 12.92
        return ((component + 0.055) / 1.055) ** 2.4

    red, green, blue = (channel(component) for component in value[:3])
    return 0.2126 * red + 0.7152 * green + 0.0722 * blue


def contrast_ratio(foreground, background):
    """WCAG ratio for two opaque colours.

    Compositing is out of scope, so a translucent input would silently produce a
    ratio for a colour nobody sees. Reject it instead of reporting a wrong number.
    """
    for value in (foreground, background):
        if len(value) > 3:
            raise ThemeParseError(
                "Contrast needs opaque colours; got alpha %s" % value[3]
            )
    first = relative_luminance(foreground)
    second = relative_luminance(background)
    lighter, darker = max(first, second), min(first, second)
    return (lighter + 0.05) / (darker + 0.05)


def wcag_grade(ratio):
    if ratio >= 7:
        return "AAA", "pass"
    if ratio >= 4.5:
        return "AA", "pass"
    if ratio >= 3:
        return "AA Large", "warn"
    return "Fail", "fail"


STYLE = """
:root{--bg:#faf9f6;--fg:#1f1b17;--muted:#6b6259;--line:#e6e0d6;--card:#fff}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#16140f;--fg:#f2ede4;--muted:#a89e92;--line:#2f2a22;--card:#1e1b15}}
:root[data-theme="dark"]{--bg:#16140f;--fg:#f2ede4;--muted:#a89e92;--line:#2f2a22;--card:#1e1b15}
*{box-sizing:border-box}
body{background:var(--bg);color:var(--fg);margin:0;padding:32px 20px 72px;
font:15px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",system-ui,sans-serif}
.wrap{max-width:1180px;margin:0 auto}
h1{font-size:26px;margin:0 0 6px;letter-spacing:-.02em}
h2{font-size:19px;margin:44px 0 14px;letter-spacing:-.01em}
h3{font-size:14px;margin:0 0 10px;color:var(--muted);font-weight:600}
p.sub{color:var(--muted);margin:0 0 4px;font-size:14px}
code{font:12.5px ui-monospace,SFMono-Regular,Menlo,monospace}
.scroll{overflow-x:auto}
table{border-collapse:collapse;width:100%;min-width:720px;font-size:13.5px}
th,td{border-bottom:1px solid var(--line);padding:9px 10px;text-align:left;vertical-align:middle}
th{color:var(--muted);font-weight:600;font-size:12px;text-transform:uppercase;letter-spacing:.05em}
.sw{width:34px;height:34px;border-radius:8px;border:1px solid rgba(128,128,128,.28);flex:0 0 auto}
.cell{display:flex;align-items:center;gap:9px}
.cell code{color:var(--muted);white-space:nowrap}
.grid{display:grid;gap:16px;grid-template-columns:repeat(auto-fit,minmax(320px,1fr))}
.card{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:18px}
.chip{display:inline-flex;align-items:center;gap:7px;font-size:12.5px;margin:0 10px 8px 0}
.dot{width:13px;height:13px;border-radius:50%;flex:0 0 auto}
.pill{display:inline-block;padding:1px 7px;border-radius:999px;font-size:11px;font-weight:700}
.pass{background:#d8f0dd;color:#14562a}.warn{background:#fdefcf;color:#6b4c07}.fail{background:#fadadd;color:#7a1420}
@media (prefers-color-scheme:dark){
:root:not([data-theme="light"]) .pass{background:#173d24;color:#8fe0a6}
:root:not([data-theme="light"]) .warn{background:#463612;color:#f0cf83}
:root:not([data-theme="light"]) .fail{background:#4a1a20;color:#f5a3ad}}
.note{color:var(--muted);font-size:12.5px;margin-top:9px}
.stage{border-radius:12px;padding:16px;margin-bottom:12px}
"""

TEXT_TOKENS = [
    "ink",
    "inkSecondary",
    "inkTertiary",
    "inkQuaternary",
    "accent",
    "attentionText",
    "destructive",
]


def render(theme):
    tokens, scales, order = theme["tokens"], theme["scales"], theme["order"]
    skins = theme["skins"]
    if CHART_TOKEN not in scales:
        raise ThemeParseError("Missing categorical chart scale")
    chart = scales[CHART_TOKEN]
    out = [
        "<!DOCTYPE html>",
        '<html lang="zh-Hans"><head><meta charset="utf-8">',
        '<meta name="viewport" content="width=device-width,initial-scale=1">',
        "<title>MindBudget Palette</title>",
        "<style>%s</style></head><body>" % STYLE,
        '<div class="wrap">',
    ]
    out.append("<h1>MindBudget 主题色板</h1>")
    out.append(
        '<p class="sub">从 <code>MindBudget/Features/Shared/AppTheme.swift</code> 直接解析生成 · '
        "%d 个 token × %d 套皮肤 · 分类色阶 %d 色</p>"
        % (len(order), len(skins), len(chart[skins[0]]))
    )
    out.append(
        '<p class="sub">色值没有一个是手抄的。主题改动后重新运行 '
        "<code>Scripts/theme_palette.py</code> 即可再生成，不会与代码漂移。</p>"
    )

    out.append("<h2>颜色 token</h2><div class=\"scroll\"><table><thead><tr><th>Token</th>")
    for skin in skins:
        english, chinese = SKIN_LABELS[skin]
        out.append(
            '<th>%s <span style="color:var(--muted);font-weight:400">%s</span></th>'
            % (english, chinese)
        )
    out.append("</tr></thead><tbody>")
    for name in order:
        out.append("<tr><td><code>%s</code></td>" % name)
        for skin in skins:
            value = tokens[name][skin]
            out.append(
                '<td><div class="cell">%s<code>%s</code></div></td>'
                % (swatch(value), swatch_label(value))
            )
        out.append("</tr>")
    out.append("</tbody></table></div>")

    out.append("<h2>分类图色阶</h2>")
    out.append(
        '<p class="sub">每套色阶显示在它自己的 <code>canvas</code> 背景上'
        "——这才是用户实际看到的对比关系。</p>"
    )
    out.append('<div class="grid">')
    for skin in skins:
        english, chinese = SKIN_LABELS[skin]
        canvas, surface, ink = tokens["canvas"][skin], tokens["surface"][skin], tokens["ink"][skin]
        colors = chart[skin]
        out.append('<div class="card"><h3>%s · %s</h3>' % (english, chinese))
        out.append('<div class="stage" style="background:%s">' % css(canvas))
        out.append('<div style="background:%s;border-radius:10px;padding:14px">' % css(surface))
        step = 100 / len(colors)
        stops = ", ".join(
            "%s %.2f%% %.2f%%" % (css(color), index * step, (index + 1) * step)
            for index, color in enumerate(colors)
        )
        out.append(
            '<div style="width:132px;height:132px;margin:0 auto 12px;border-radius:50%%;'
            "background:conic-gradient(%s);"
            "-webkit-mask:radial-gradient(circle,transparent 52%%,#000 52.6%%);"
            'mask:radial-gradient(circle,transparent 52%%,#000 52.6%%)"></div>' % stops
        )
        for index, color in enumerate(colors):
            out.append(
                '<span class="chip" style="color:%s"><span class="dot" style="background:%s">'
                "</span>%d</span>" % (css(ink), css(color), index + 1)
            )
        out.append("</div></div>")
        out.append(
            '<div class="scroll"><table style="min-width:0"><thead><tr><th>分段</th>'
            "<th>对 surface 对比度</th><th></th></tr></thead><tbody>"
        )
        for color in colors:
            ratio = contrast_ratio(color, surface)
            grade, css_class = wcag_grade(ratio)
            out.append(
                '<tr><td><div class="cell">%s<code>%s</code></div></td>'
                '<td><code>%.2f</code></td><td><span class="pill %s">%s</span></td></tr>'
                % (swatch(color, 20), swatch_label(color), ratio, css_class, grade)
            )
        out.append("</tbody></table></div>")
        out.append(
            '<p class="note">图例始终显示分类名称，颜色不是唯一区分通道，'
            "因此这里的对比度是可读性参考而非硬门槛。</p></div>"
        )
    out.append("</div>")

    out.append("<h2>文字对比度</h2>")
    out.append(
        '<p class="sub">在 <code>surface</code> 上。WCAG 正文阈值 AA 4.5、AAA 7。</p>'
    )
    out.append('<div class="scroll"><table><thead><tr><th>Token</th>')
    for skin in skins:
        out.append("<th>%s</th>" % SKIN_LABELS[skin][0])
    out.append("</tr></thead><tbody>")
    for name in TEXT_TOKENS:
        if name not in tokens:
            continue
        out.append("<tr><td><code>%s</code></td>" % name)
        for skin in skins:
            ratio = contrast_ratio(tokens[name][skin], tokens["surface"][skin])
            grade, css_class = wcag_grade(ratio)
            out.append(
                '<td><div class="cell"><div class="sw" style="width:22px;height:22px;'
                "background:%s;display:flex;align-items:center;justify-content:center;"
                'color:%s;font:700 12px/1 sans-serif">A</div><code>%.2f</code> '
                '<span class="pill %s">%s</span></div></td>'
                % (css(tokens["surface"][skin]), css(tokens[name][skin]), ratio, css_class, grade)
            )
        out.append("</tr>")
    out.append("</tbody></table></div></div></body></html>")
    return "\n".join(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("theme", help="path to AppTheme.swift")
    parser.add_argument("output", nargs="?", help="HTML file to write; omit to print JSON")
    arguments = parser.parse_args()

    with open(arguments.theme, encoding="utf-8") as handle:
        theme = parse_theme(handle.read())

    if arguments.output is None:
        print(json.dumps(theme, indent=1, ensure_ascii=False))
        return

    with open(arguments.output, "w", encoding="utf-8") as handle:
        handle.write(render(theme))
    print(
        "Wrote %s from %d tokens across %d skins"
        % (arguments.output, len(theme["order"]), len(theme["skins"]))
    )


if __name__ == "__main__":
    main()
