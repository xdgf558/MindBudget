# COPY_GUIDELINES

## Three rules

1. Describe the situation, never the person.
2. Every purchase reminder offers 2–4 choices, including continuing the purchase.
3. Give numbers, not verdicts.

## Emotion-tag display names

Keep display names synchronized with section 12.2 of the authoritative specification.
Store localization keys rather than rendered labels in persisted data.

## Banned phrases

The future `Resources/BannedPhrases.json` contains Chinese and English phrases.
`AdviceSafetyValidator` checks generated text, not fixed UI labels.

## Tone variants

- `soft`: at most 80 characters, includes context, may ask one question.
- `direct`: at most 40 characters, plain statement.
- `minimal`: at most 20 characters, numbers only, no advice.

## Never

- Use exclamation marks in reminders.
- Use red as the sole signal for overspending; use amber and explanatory text.
- Celebrate skipping a purchase with animations.
- Say "you saved X by not buying."
- Use clinical or diagnostic labels such as anxiety, depression, compulsion, or addiction.
