# claude-code-gauge

Your Claude Code quotas at a glance, right in the macOS menu bar.

Two small gauges show the current session (top) and the current week (bottom). They turn orange at 70% and red at 90%. Click them for exact percentages, reset times and refresh settings.

Quotas are read with Claude Code's `/usage` command, which never calls the model: checking them uses no tokens.

## Requirements

- macOS 14 (Sonoma) or later
- [Claude Code](https://docs.claude.com/en/docs/claude-code/setup) installed and logged in with a Claude subscription (Pro or Max)

## Installation

```bash
git clone https://github.com/cmtdrt/claude-code-gauge.git
cd claude-code-gauge
./scripts/build.sh --install
```

The script builds the app, copies it to `/Applications` and launches it.

## Updating

```bash
git pull
./scripts/build.sh --install
```
