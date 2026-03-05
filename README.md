# web-chat

OpenClaw skill that sends messages to AI chatbots (Google Gemini, ChatGPT) via Playwright browser automation and returns responses with citations.

## Setup

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
```

## Usage

Start Chrome with remote debugging, then run a script:

```bash
# Start Chrome (only needed once)
scripts/start_chrome.sh

# Ask Gemini
.venv/bin/python3 scripts/ask_gemini.py "your question"

# Ask ChatGPT
.venv/bin/python3 scripts/ask_chatgpt.py "your question"
```

Options: `--new-chat`, `--timeout SECS`, `--json`, `--port PORT`.

## Requirements

- Python 3.10+
- Google Chrome
- Playwright (`pip install playwright`)
