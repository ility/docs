# Ility voice and tone

This is the one voice and tone guide for everything Ility Labs writes or says:
the app, the customer docs, the marketing site, the engine and its rules, social
posts, interviews, podcasts, and talks.

Ility checks whether content works for real people, so its own words have to meet
that standard. Plain, specific, and on the reader's side, everywhere.

This file lives in the public `ility/docs` repository so open-source repositories
can link to it. `.mintignore` keeps it off docs.ilitylabs.com.

## Foundation

Every register and channel follows these rules.

- Use plain words. If a technical term is unavoidable, define it the first time
  it appears.
- Lead with people. Say who is affected and how their experience changes.
- Use active voice and present tense.
- Write in US English.
- Address the reader as "you".
- Use contractions ("don't", "you'll"). They read as natural speech.
- Keep sentences short, one idea each.
- Avoid idioms, metaphors, and culturally specific references. They don't
  translate and they don't age well.
- Never use "simply", "just", "easy", or "obviously". They alienate anyone who
  doesn't find the thing simple.
- No hype words: "powerful", "seamless", "delightful", "robust", "world-class",
  "revolutionary", "game-changing".
- No exclamation marks.
- No lecturing, scolding, or blame. Explain; don't judge.

## Registers

Ility writes in three registers on that shared foundation.

| Register | Where | Character |
| --- | --- | --- |
| Product | App UI, rule content, error messages, CLI output, MCP responses, customer docs | Conversational but brief, friendly but succinct. Teaches without assuming expertise. Quick to scan. |
| Brand | Marketing site, social, email, interviews, podcasts, talks | Same plain language with more rhythm and conviction. Confident, calm, and never oversold. |
| Engineering | READMEs, agent instruction files, code, type docs | Terse, technical, and declarative. Reference material for people who already know what they want. |

### Product

The reader is often a designer, content writer, product manager, or QA tester,
not only an engineer. They should feel Ility is explaining accessibility to them,
not gatekeeping it.

- Teach, don't catalog. Explaining the person affected beats quoting WCAG.
- Stay concise. Inviting doesn't mean wordy. Cut anything that doesn't earn its
  place.
- Buttons and menu items are verbs in sentence case: **Run scan**, **Add surface**.
- Empty states say what belongs there and how to start.
- In docs, bold UI labels exactly as the app spells them: choose **Run scan**.
- Don't promise prices, plan limits, or dates outside the pricing page.

### Brand

The marketing home page sets the model: "Accessibility is ongoing. Managing it
should be too." Short lines, a clear point of view, and no oversell.

- Earn trust with specifics: a real finding, a before and after, a number with its
  source.
- Say what Ility does and doesn't do. "It does not place an overlay on your
  website" is stronger than any adjective.
- Short fragments are fine for rhythm. Use them on purpose, not by habit.
- Em dashes are fine in moderation. In product and docs, prefer a period.

### Engineering

Match the existing tone of each repository's `README.md` and agent instructions.

## Names

- The product is **Ility**, with a capital I, including in the middle of a
  sentence.
- The company is **Ility Labs**.
- Lowercase only where the source is lowercase: the logo, package and repository
  names (`ility-core`, `ility/docs`), URLs, and code.
- Never write "ILITY", "iLity", or "ility" in prose.

## "We" and "Ility"

- The product never says "we". Ility scans, finds, reports, and loads. It doesn't
  think, want, or believe.
  - Good: "Ility found 412 pages on example.com."
  - Bad: "We found 412 pages on example.com."
- The people at Ility Labs say "we" when they mean themselves: a support offer in
  the docs ("we'll send you an invitation"), a founder's post, or an answer on a
  podcast.

## Talking about disability

- Lead with people, not conditions: "blind and low-vision people", "people who use
  a keyboard instead of a mouse".
- Use "disabled people" or "people with disabilities", and follow an individual's
  own preference when you know it.
- Never use "suffers from", "confined to a wheelchair", "handicapped", "special
  needs", or "differently abled".
- Don't use disability as a metaphor: "blind spot", "crippling", "falling on deaf
  ears", "lame".

## Claims

- Never promise compliance, "100% accessible", or protection from lawsuits.
- Automated testing finds some issues, not all. Say so wherever results appear,
  and say that people review the rest.
- Never describe Ility as an overlay or imply it fixes a website by itself.
- Cite the source of every statistic.
- Don't name a competitor to knock it. Describe the approach instead.

## Error messages

State what went wrong, then what to do about it. Name the offending input by
value when it helps. No blame: the reader is debugging, so be on their side.

- Good: ``Rule `image-alt-meaningful` is missing the `severity` field. Add one of: critical, serious, moderate, minor.``
- Bad: "You forgot to set severity."
- Bad: "Invalid rule." (No information.)

## Mechanics

### Capitalization

- Headings, buttons, and labels use sentence case.
- Match code and UI verbatim: `aria-label` stays lowercase at the start of a
  sentence.
- Standards: WCAG, ARIA, ADA, Section 508, EN 301 549.

### Punctuation

- End full sentences with a period and questions with a question mark.
- Use the Oxford comma.
- One space between sentences.
- No emoji in product copy, docs, rule content, or commit messages. Social has
  its own rule below.

### Lists

- Start each item with a capital letter.
- Make every item a full sentence or every item a fragment. Don't mix.
- Full sentences end with a period. Fragments don't.
- Use ordered lists for sequences and unordered lists for sets.

### Numbers

- Spell out zero through nine in prose. Use numerals for 10 and up.
- Always use numerals for versions, criteria, counts in the UI, and percentages:
  "WCAG 2.2", "affects 3 pages", "40%".

### Emphasis and code

- Bold for emphasis, for UI labels, and for the first use of a defined term.
- Italic only for titles of works.
- Never use all caps for emphasis.
- Inline code for identifiers, attributes, selectors, file paths, and commands.
  Fenced code blocks with a language tag for examples.

## Channels

An accessibility company is judged on whether its own posts and talks are
accessible. Each channel starts there.

### Social media

- Add alt text to every image and captions to every video.
- Write hashtags in camel case: `#DigitalAccessibility`.
- Don't use emoji as bullets or decoration; screen readers read each one aloud.
  One emoji at the end of a post, at most, and only on casual channels.
- Don't use Unicode "bold" or "italic" letters. Screen readers can't read them.
- Put the point in the first line. Most people never tap "more".
- One idea per post.
- Show, don't boast: a real finding or fix beats a feature claim.
- Reply like support: calm, specific, and on the person's side, even when the
  post is hostile.

### Interviews and podcasts

Three messages to return to:

1. Accessibility is ongoing work, not a one-time audit.
2. Automated testing finds a real share of issues, and people handle the rest.
3. Ility helps teams manage that work in the open, not hide it behind an overlay.

- Say what you know. "I'd need to check" beats a guess.
- Speak the way the docs read: short sentences, and define acronyms on first use
  ("WCAG, the web accessibility standard").
- Ask for a transcript of every episode and captions on every video, and share
  them.

### Speaking and presentations

- Read slide text aloud and describe charts and images.
- Use high contrast and large text. Don't carry meaning by color alone. No
  flashing animation.
- Share the slides as an accessible file before or right after the talk.
- Ask for live captions, and make sure every question gets a microphone.

## Rule content

Rule titles, `why` text, and remediation notes are the most-read product copy.
`ility-core` keeps the rule-specific guidance (title format, `why` length, and
examples) next to the rules, and it follows this guide.
