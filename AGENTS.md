# AGENTS.md

Guidelines for AI coding agents working in this repository.

## Project Overview

OpenClaw skill that automates AI chatbot interaction (Google Gemini, ChatGPT) via
Playwright browser automation over Chrome DevTools Protocol (CDP). No framework, no
package — just standalone Python scripts and a shell launcher.

### Structure

```
scripts/
  ask_gemini.py    # Gemini browser automation (CLI entry point)
  ask_chatgpt.py   # ChatGPT browser automation (CLI entry point)
  start_chrome.sh  # Launch Chrome with --remote-debugging-port
SKILL.md           # OpenClaw skill definition (agent reads this at runtime)
_meta.json         # Skill metadata (slug, version)
requirements.txt   # Python deps (playwright)
```

## Environment Setup

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
```

Python 3.10+. Single dependency: `playwright>=1.40.0`.

## Running Scripts

```bash
# Start Chrome with CDP (required first)
scripts/start_chrome.sh

# Run against Gemini
.venv/bin/python3 scripts/ask_gemini.py "query"

# Run against ChatGPT
.venv/bin/python3 scripts/ask_chatgpt.py "query"

# Common flags: --port 9222, --timeout 120, --new-chat, --json
```

Scripts require a live Chrome instance with `--remote-debugging-port=9222`.
There is no way to run them without a browser.

## Lint / Format

No formal config exists. Use ruff (cache in `.ruff_cache/`):

```bash
.venv/bin/pip install ruff
ruff check scripts/          # lint
ruff format scripts/         # format
ruff check scripts/ask_gemini.py   # single file
```

## Tests

No test suite exists. Scripts are integration-only (require live Chrome + login).
To verify a script change works, run it against a live browser:

```bash
.venv/bin/python3 scripts/ask_gemini.py --json "hello"
```

Check that `"success": true` appears in the JSON output.

## Code Style

### Python Conventions

- **Python version**: 3.10+ (uses `list[str]`, `dict`, `set[str]` — no `typing.List`)
- **Formatter**: ruff format (88 char line width, double quotes, trailing commas)
- **Shebang**: `#!/usr/bin/env python3` on every script
- **Module docstring**: Required at top of every script — describe purpose and usage

### Imports

Standard library first, blank line, then third-party. Alphabetical within groups:

```python
import argparse
import json
import sys
import time
from urllib.parse import urlparse

from playwright.sync_api import sync_playwright, Page, TimeoutError as PlaywrightTimeout
```

Only import what you use. No unused imports.

### Naming

- **Constants**: `UPPER_SNAKE_CASE` — defined at module level after imports
- **Functions**: `snake_case`
- **Variables**: `snake_case`
- **Selector lists**: Named `*_SELECTORS` (e.g. `INPUT_SELECTORS`, `SEND_BUTTON_SELECTORS`)

### Type Annotations

- Annotate function signatures: parameters and return types
- Use built-in generics: `list[str]`, `dict`, `set[str]` (not `typing.List`)
- Playwright types: `Page` from `playwright.sync_api`

```python
def find_element(page: Page, selectors: list[str], timeout: int = 5000):
def send_message(page: Page, message: str, timeout_seconds: int = 120) -> dict:
def extract_citation_links(page: Page) -> list[dict]:
```

### Error Handling

- **Playwright operations**: Wrap in try/except, never let a selector failure crash the script
- **Fallback chains**: Try multiple selectors/methods in order (fill → type → keyboard)
- **Bare `except Exception`**: Acceptable for Playwright DOM operations that may fail
  silently (element detached, page navigated, etc.)
- **User-facing errors**: Print to stderr with prefix `ERROR:`, then `sys.exit(1)`
- **Progress messages**: Print to stderr with prefix `[*]` (info) or `[!]` (warning)
- **Never close the browser** — it's the user's Chrome instance

```python
# Progress/debug → stderr
print("[*] Waiting for response...", file=sys.stderr)
print("[!] Timeout reached.", file=sys.stderr)

# Fatal errors → stderr + exit
print("ERROR: Cannot connect to Chrome.", file=sys.stderr)
sys.exit(1)

# Actual response data → stdout (so it can be piped/parsed)
print(result["response_text"])
```

### Script Architecture Pattern

Both `ask_gemini.py` and `ask_chatgpt.py` follow the same structure. New chatbot
scripts MUST follow this pattern:

1. **Constants section**: URLs, selector lists (`INPUT_SELECTORS`, `SEND_BUTTON_SELECTORS`,
   `STOP_BUTTON_SELECTORS`, `RESPONSE_SELECTORS`)
2. **Helpers section**: `find_element()`, `wait_for_response_complete()`,
   `get_all_response_elements()`, `get_last_response_text()`, `extract_citation_links()`,
   `send_message()`
3. **Main section**: argparse CLI with `message`, `--port`, `--timeout`, `--new-chat`, `--json`
4. **Output**: Structured text (header + body + citations) or JSON via `--json`

### Selector Lists

Selectors are fragile — chatbot UIs change frequently. Follow these rules:

- Order selectors by specificity: most specific first, broadest last
- Include multiple fallbacks (at least 3 per selector list)
- Verify elements have non-empty `inner_text()` before using them
- Skip selectors that match empty elements (Web Component / shadow DOM edge cases)
- Include both English and Chinese aria-labels where applicable

### Response Detection

Use the `existing_count` pattern to detect NEW responses:

```python
existing_responses = len(get_all_response_elements(page))
# ... send message ...
# wait_for_response_complete checks len(elements) > existing_count
```

### Shell Scripts

- Shebang: `#!/usr/bin/env bash`
- `set -euo pipefail` at top
- Quote all variables: `"$PORT"`, `"$USER_DATA_DIR"`
- Chrome user data dir: `~/.openclaw/workspace/chrome_profile` (never `/tmp`, must persist)

## SKILL.md Guidelines

SKILL.md is read by the OpenClaw agent at runtime. When editing:

- **Writing style**: Imperative mood, no pronouns ("Send the query" not "You should send")
- **Keep it concise**: Currently ~80 lines — avoid bloat
- **Query extraction rule**: Strip trigger prefix only, pass user query verbatim
- **Frontmatter description**: Must include trigger phrases in English and Chinese
