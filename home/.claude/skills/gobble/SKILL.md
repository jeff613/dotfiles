---
name: gobble
description: Use when the user says "gobble" or "gobble mode", or asks you to keep working unattended while they are away (asleep, out, travelling) - an autonomous session against a stated goal with a time or quota budget. Also use when a session realizes mid-run that the user is gone and it is expected to continue alone.
---

# Gobble Mode

## Overview

Gobble is the counterpart to careful supervised work: an unattended session that works toward the user's stated goal inside a resource contract, in an isolated worktree, leaving a report they read when they return. **The budget is a ceiling, not a target** - unspent quota is a fine outcome; the goal being done is the only success metric. See DESIGN.md (same directory) for rationale and decision history.

## Preflight - can this session survive alone?

Do this before anything else. Read `permissions.defaultMode` from `~/.claude/settings.json` (missing file or key = `default`):

| Mode | Verdict |
|---|---|
| `bypassPermissions` | Good - proceed. |
| `auto` | Proceed, and say so in the launch confirmation: a classifier may auto-deny individual calls. Denials are skips, not stalls, so the run survives - it just may cover less. |
| anything else (`default`, `acceptEdits`, `plan`) | **The run will hang.** The first unmatched command opens a permission prompt with nobody there to answer it, and everything after it waits. |

On a hanging mode: tell the user plainly that the run will stall on the first prompt, and that the fix is to relaunch with `claude --dangerously-skip-permissions` or set `"permissions": {"defaultMode": "bypassPermissions"}` in `~/.claude/settings.json`. **Do not start the run until they answer.** A session started with the CLI flag does not show up in settings.json, so if they say they are already bypassed, take their word.

If the user has already left and the mode is hanging: do not start a long run. Do the smallest useful read-only work, write the report explaining the run could not start and how to fix it, and stop. A clear "didn't start" beats a session frozen on a dialog for eight hours.

## Launch (user still present)

Elicit anything missing, then confirm the whole contract back in one paragraph before they leave:

1. **Goal** - and what "done" observably means. If the goal is a list, it is ranked.
2. **Time ceiling** - a clock time or duration ("until 8am", "next 5 hours").
3. **Quota ceiling** - which windows may be eaten, with a number ("stop if weekly hits 60%"). If the user states none, the default is: current 5-hour window only, and never past 80% weekly.

If the user is already gone and no contract was stated: adopt the default quota ceiling above, time ceiling = end of current 5-hour window, and record in the report that the contract was defaulted, not given.

Then set up: worktree at `~/worktrees/<repo>/<goal-slug>` branched from the integration branch (main checkout stays untouched - other sessions may be live in it); `caffeinate -dims -t <contract-seconds + margin> &` in the background (macOS ships `caffeinate`; on other platforms skip it and note that sleep settings are the user's problem); `GOBBLE-REPORT.md` skeleton in the worktree root.

## Pacing loop

Every round, in this order:

1. **Contract check first.** `date`, then `bash ~/.claude/skills/gobble/scripts/check-usage.sh`. Past the time ceiling or any quota ceiling → go to Shutdown. Usage check failing → note it once in the report and pace by time alone with double headroom margins.
2. **Schedule before working.** `ScheduleWakeup` for 30-45 min out, *before* the work stretch, so a mid-stretch death has a pending revival. The wakeup prompt must contain the contract verbatim (goal, ceilings, report path) - it re-arrives every round and survives context compaction.
3. **Headroom rule.** Session (5h) window above 85% → no new work stretch; nap toward `resets_at` with chained wakeups (1h max per hop, re-checking usage at each), provided the time ceiling extends past the reset.
4. **Work one bounded stretch** inside the goal: smallest reviewable unit, commit it with a clear message, append one timeline line to the report. Then loop.

A denied permission is never worked around - note it in the report, skip that item, continue with what's allowed.

## Goal-done and stalled conditionals

- **Goal verifiably done** (its "done" criteria pass, fresh build/test run as evidence) → verification pass, then Shutdown - regardless of remaining time or quota. Improvements noticed along the way (deprecated APIs, thin coverage, refactor candidates) go in the report as a proposed menu with effort estimates. Implementing any of them is the user's decision when they return, not this session's work: unreviewed diffs they didn't ask for cost them more to untangle than the tokens they burned.
- **Item stalled** (about two rounds with no real progress) → write up what was tried and why it failed, move to the next goal item; no next item → Shutdown.

| Excuse (verbatim from baseline testing) | Reality |
|---|---|
| "This fix has objective correctness value - defensible autonomous work" | Objectively good ≠ sanctioned. Document it, don't do it. |
| "Stopping now would waste an explicit grant of time and quota" | The grant was for the goal. Ceiling, not target. |
| "Only 20 more minutes to finish" | Hard-file estimates overrun; the ceiling is already the decision. |

## Hard rules

- Never `git push`, never merge, nothing leaves the machine.
- Never edit `~/.claude/settings.json` or change the permission mode yourself. The preflight *tells* the user what to set; granting your own session more access is their decision, never this session's.
- Writes only in the gobble worktree(s), scratchpad, and the report; main checkout is read-only.
- No credential access beyond `check-usage.sh`; no destructive git commands outside the worktree.

## Shutdown hygiene

1. Mid-item work: commit as clearly-labeled WIP naming exactly what remains.
2. Finalize the report: goal status against its "done" criteria, build/test state at last commit, what was tried and abandoned (with why), decisions made that are the user's to overrule, proposed-but-not-done menu, ranked "review me in this order" list, and what stopped the run (done / time / quota / stall).
3. `ScheduleWakeup` with `stop: true`; kill the caffeinate process.
4. Final message = the TLDR of the report, stated plainly.

## Report skeleton (`GOBBLE-REPORT.md`)

```markdown
# Gobble Report - <date>
**Goal:** ...  **Contract:** <time ceiling; quota ceilings; defaulted?>
**Status:** IN PROGRESS | DONE | STOPPED (<reason>)
## Review me in this order
## Timeline            <!-- one line per round -->
## Decisions yours to overrule
## Proposed, not done
## Test/build state
```

## Common mistakes

- Working first and scheduling the wakeup after - one mid-stretch death ends the whole run.
- Treating leftover budget as work to be invented ("gold-plating"). Stop is a valid, good ending.
- Retrying the usage check in a loop when it fails - degrade to time-based pacing instead.
- A report that narrates effort instead of ranking what the user should review first.
