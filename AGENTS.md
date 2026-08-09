# Project notes for agents

Deliberate decisions in this repo - do NOT silently revert them:

- `homebrew.onActivation.cleanup = "none"` in `configuration.nix` is intentional (changed from upstream's `"zap"` on 2026-08-08). The declared brews/casks are the shared essentials every machine gets; each machine may additionally install its own Homebrew packages ad-hoc, and the switch must never uninstall them. Do not tighten this to `uninstall` or `zap`.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
