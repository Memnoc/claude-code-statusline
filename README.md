# claude-code-statusline

A configurable, Rose Pine-themed statusline for [Claude Code](https://claude.ai/code). Displays context window usage, rate limits, cache efficiency, session cost, git state, and more — rendered as a compact bar at the bottom of every session.

---

## What it shows

```
~/Code/myproject | ⎇ main !+ | claude-sonnet-4-5 | 🧠 ████░░░░░░ 42% | ⚡ ██░░░░░░░░ 17% ~3h58m | 💾 █████████░ 91% | ⏱ 1h12m | $1.93 | +246 -83
```

| Segment | Description |
|---|---|
| Directory | Working directory, abbreviated to last 3 components |
| `⎇ branch` | Git branch + status flags (`!` modified, `+` staged, `?` untracked) |
| Model | Active Claude model |
| 🧠 Context | Context window usage bar — color shifts at 30%, 60%, 80% |
| ⚡ Rate limit | Five-hour rate limit bar + time until reset (e.g. `~3h58m`) |
| 💾 Cache | Lifetime cache-read ratio from `stats-cache.json` |
| ⏱ Duration | Time elapsed since session start |
| Cost | Session cost in USD (hidden at $0.00) |
| Lines | Lines added/removed this session (hidden when both zero) |

---

## Requirements

- Claude Code
- `bash` 4+ (macOS ships bash 3; install via `brew install bash`)
- `jq`
- `git`

---

## Installation

```bash
git clone https://github.com/matteostara/claude-code-statusline
cd claude-code-statusline
bash install.sh
```

Then complete two manual steps.

**1. Wire the renderer in `~/.claude/settings.json`:**

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash \"$HOME/.claude/statusline-command.sh\""
  }
}
```

**2. Add to `~/.zshrc` (prevents function/binary name collision):**

```zsh
statusline() { command statusline "$@"; }
```

Ensure `~/.local/bin` is in `PATH`, then restart Claude Code.

---

## Configuration

Config file: `~/.claude/statusline.conf`

```bash
THEME="dawn"   # dawn | moon | main
SIZE="full"    # full | small | minimal
```

Use the `statusline` CLI from any terminal — or from inside Claude Code with `! statusline --help`.

**Themes:**
```bash
statusline --themes                   # list all themes (* marks active)
statusline --theme nord               # switch to Nord
statusline --theme catppuccin-mocha   # switch to Catppuccin Mocha
statusline --theme dawn               # back to default
```

**Size presets:**
```bash
statusline --config full      # all segments, 10-block bars (default)
statusline --config small     # all segments, 5-block bars
statusline --config minimal   # directory + model + context only
```

**Segments:**
```bash
statusline --segments          # list all segments and their state (* = off)
statusline --segment git:off   # hide git branch
statusline --segment cost:on   # show session cost
```

**Other:**
```bash
statusline --show    # print current config file
statusline --reset   # revert all settings to defaults
```

### Themes

| Theme | Mode | Palette |
|---|---|---|
| `dawn` | light | Rose Pine Dawn |
| `moon` | dark | Rose Pine Moon |
| `main` | dark | Rose Pine |
| `catppuccin-latte` | light | Catppuccin Latte |
| `catppuccin-mocha` | dark | Catppuccin Mocha |
| `nord` | dark | Nord |
| `gruvbox` | dark | Gruvbox Dark |
| `tokyo-night` | dark | Tokyo Night |
| `solarized` | light | Solarized Light |

### Size presets

| Preset | Bars | Segments |
|---|---|---|
| `full` | 10 blocks | All |
| `small` | 5 blocks | All |
| `minimal` | 10 blocks | Directory, model, context only |

### Segments

Each segment can be shown or hidden independently. At least one must remain on.

| Name | Description |
|---|---|
| `dir` | Working directory |
| `git` | Git branch and status flags |
| `model` | Active model name |
| `ctx` | Context window usage bar |
| `rate` | Rate limit bar with reset countdown |
| `cache` | Lifetime cache efficiency bar |
| `duration` | Time since session start |
| `cost` | Session cost in USD |
| `diff` | Lines added/removed this session |
| `caveman` | Caveman mode badge (if plugin active) |

---

## How it works

Claude Code supports a `statusLine.type: "command"` hook in `settings.json`. On every prompt, it pipes a JSON payload to your command and renders the stdout as the statusline. This script reads that payload for live session data (context usage, rate limits, cost, lines changed) and supplements it with data from local files (`stats-cache.json` for lifetime cache stats, `sessions/*.json` for session start time).

Progress bars use Unicode block characters (`█░`) and ANSI 256-color codes, chosen from the Rose Pine palette based on the active theme.

---

## License

MIT
