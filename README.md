# claude-code-gauge

Your Claude Code quotas at a glance, right in the macOS menu bar.

Two small gauges show the current session (top) and the current week (bottom). They turn orange at 70% and red at 90%. 
<p align="center">
  <img width="195" height="33" alt="image" src="https://github.com/user-attachments/assets/5ed8c7db-655d-434e-b34f-bab1ab1dc54d" />
  <img width="195" height="33" alt="image" src="https://github.com/user-attachments/assets/1cdcd40f-3b17-4ff5-b2d1-d5f7c3341dc4" />
  <img width="195" height="33" alt="image" src="https://github.com/user-attachments/assets/7f85965f-4288-4d5d-a228-7992240374c7" />
</p>

Click them for exact percentages, reset times and refresh settings.
<p align="center">
  <img width="304" height="271" alt="image" src="https://github.com/user-attachments/assets/ae30ec09-70e1-424a-ac01-4846ec047786" />
</p>

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
