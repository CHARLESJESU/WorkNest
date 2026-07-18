---
name: worknest-ui
description: WorkNest app-wide branding and UI rules — color roles, button conventions, shared style source. Use whenever building or editing ANY screen in this app (not just login), to keep colors/spacing consistent across the whole app. Trigger on "UI", "screen", "widget", "button", "color", "brand", "design", "polish".
---

# WorkNest UI

App-wide design rules for WorkNest. Single source of truth: `lib/login/branding.dart`, class `WNColors`. Reuse it everywhere — never hardcode hex colors in new screens.

## Color roles (fixed — do not swap)

- **`WNColors.blue`** (`0xFF1E6FF0`) — primary brand color. ALL action buttons/CTAs use this: Login, Signup, Apply Job, Post Job, Save, Submit, Check Email, Reset Password, etc. Also used for icons, focused input borders, link text.
- **`WNColors.orange`** (`0xFFFF7A1A`) — highlight/secondary accent ONLY. Badges, "New" tags, notification dots, featured/promoted job cards, promotional banners, inline text links (e.g. "Sign Up" link on login screen). NEVER used as a primary button background.
- **`WNColors.navy`** (`0xFF0A1748`) — headings, titles, back-icons.
- **`WNColors.navyDeep`** (`0xFF060F30`) — deep navy variant, gradients/dark surfaces.
- **`WNColors.bg`** (`0xFFF6F8FC`) — scaffold/page background.

Rule of thumb: if it's tappable and triggers the main action of the screen → blue. If it's decorative/attention-grabbing but not the primary action → orange.

## Process
1. Read target screen fully before editing. Check for existing shared widgets/constants (`WNColors`, shared button/card widgets) — reuse, don't reinvent.
2. If a new screen needs `WNColors` but is outside `lib/login/`, import `branding.dart` rather than duplicating the hex values.
3. Fix root cause: if a color is wrong app-wide, fix at the shared style/theme level, not per-screen patches.

## Design rules
- **Spacing scale**: 4/8/16/24/32 multiples only.
- **Typography**: clear hierarchy (headline/title/body/caption), no scattered manual `fontSize`.
- **Contrast**: WCAG AA, 4.5:1 for body text. Avoid pure black/white.
- **Touch targets**: min 44x48 logical px.
- **Responsiveness**: `LayoutBuilder`/`MediaQuery`/`Flexible`/`Expanded`, no fixed widths.
- **States**: loading/empty/error designed for every data-driven screen.
- **Motion**: implicit animations, 150-300ms, purposeful only.
- **Platform feel**: Material 3 (`useMaterial3: true`) unless Cupertino explicitly required.

## Ladder before adding packages
1. Material/Flutter stdlib already covers it? Use that.
2. Already a pattern in this app (`WNColors`, existing button/card widget)? Extend it.
3. Only add a UI package if a real gap remains — check pubspec for one already installed first.

## Output
Code first. One-line note on the design decision, only if non-obvious. No design essays.
