# COPY_GUIDELINES

## Three rules

1. Describe the situation, never the person.
2. Every purchase reminder offers 2–4 choices, including continuing the purchase.
3. Give numbers, not verdicts.

## Emotion-tag display names

Keep display names synchronized with section 12.2 of the authoritative specification.
Store localization keys rather than rendered labels in persisted data.

| Raw value | Simplified Chinese | English | Never use |
|---|---|---|---|
| `imageBoost` | 想让状态更好 | Wanted to feel put-together | 虚荣 / vain |
| `socialPressure` | 社交场合 | Social occasion | 随大流 / peer pressure |
| `impulse` | 临时起意 | Spur of the moment | 冲动 / 剁手 |
| `stressed` | 压力大的时候 | Under pressure | 焦虑症 / anxious |
| `anxious` | 担心的时候 | Feeling worried | 焦虑症 / anxiety disorder |
| `lonely` | 一个人的时候 | On my own | 孤独症 / 抑郁 |

## Banned phrases

The future `Resources/BannedPhrases.json` contains Chinese and English phrases.
`AdviceSafetyValidator` checks generated text, not fixed UI labels.

## Wishlist decisions

Purchased, skipped, extended, and archived are neutral records of the user's choice.
Neither purchasing nor skipping receives praise, blame, a score, an animation, or an
invented "saved" amount. Cooling-off completion means it is time to review, not that one
outcome is preferred.

## Tone variants

- `soft`: at most 80 characters, includes context, may ask one question.
- `direct`: at most 40 characters, plain statement.
- `minimal`: at most 20 characters, numbers only, no advice.

Phase 5 templates are the mandatory offline fallback. A purchase sheet shows one
highest-severity message and 2–4 actions; Continue Purchase is the primary action, never a
punitive secondary escape. Informational insights and minimal tone remain noninterrupting.
Disabling check-ins suppresses presentation only and must not erase factual local insights.
When advanced rule evidence is shown, label the supporting and total sample counts together with
the integer confidence ratio. Do not describe that ratio as a probability, prediction, diagnosis,
or guarantee; it is only the reproducible share of samples supporting the deterministic rule.

## Lock-screen notifications

Cooling-off notifications are user-booked review cues, not purchase verdicts. The title may
name the wishlist item and the body may state the elapsed cooling duration, but neither may
contain an amount or raw note. If permission or scheduling fails, say that the local
cooling-off period still exists and give an actionable System Settings path when relevant.
Quiet-hour deferral must be described as a later delivery, never as a lost reminder.
If one stored cooling-off record cannot be read, state that fact without blame and confirm
that other valid reminders were still updated; do not collapse partial reconciliation into
a generic success or failure message.

## Never

- Use exclamation marks in reminders.
- Use red as the sole signal for overspending; use amber and explanatory text.
- Celebrate skipping a purchase with animations.
- Say "you saved X by not buying."
- Use clinical or diagnostic labels such as anxiety, depression, compulsion, or addiction.
