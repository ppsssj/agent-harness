# Verification rules

Verification is a fresh observation after the change, selected to fit the repository and risk. Prefer deterministic checks and narrow feedback first, then broader relevant checks. A green test that does not exercise the changed behavior is not sufficient evidence.

Consider formatting, lint, typecheck, unit and integration tests, build, runtime smoke checks, browser and responsive checks, accessibility, security, and a golden path. Do not require irrelevant gates. Inspect the diff and working tree in every change intended for review.

Report each applicable gate as `PASS`, `FAIL`, `NOT AVAILABLE`, or `NOT RUN`, including the exact command or observation. Never hide a relevant failed gate behind successful ones. For significant visual work, report the visual-critique status beside the mechanical gates (for example `Visual critique: VISUAL_PASS`, `Responsive browser checks: PASS`, `Build: PASS`); an unavailable render is `VISUAL_NOT_AVAILABLE`, never a pass. See [templates/verification-report.md](../templates/verification-report.md).
