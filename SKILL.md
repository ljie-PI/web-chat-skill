---
name: web-chat
description: Use when the user wants to ask Google Gemini or ChatGPT a question, search for information via an AI chatbot, or get a chatbot's opinion on a topic. Triggers on phrases like "ask Gemini", "ask ChatGPT", "ask GPT", "let Gemini answer", "search with ChatGPT", "check with Gemini", "use GPT to look up", "问一下 Gemini", "问一下 ChatGPT", "用 Gemini 查", "用 GPT 查", "让 Gemini 回答", "让 ChatGPT 回答", "用 ChatGPT 搜索". Sends the user's query to the target chatbot via browser automation and returns the response with any citation links.
version: 1.0.0
metadata:
  openclaw:
    emoji: "\u2728"
    category: "ai-tools"
    tags: ["gemini", "google", "chatgpt", "openai", "gpt", "browser-automation", "playwright", "ai-chat"]
    os: [linux, macos]
    requires:
      bins: ["python3", "google-chrome"]
---

# Web Chat

Send messages to AI chatbots (Gemini, ChatGPT) via Playwright browser automation and return responses with citations.

| Chatbot | Script | Website |
|---------|--------|---------|
| Google Gemini | `scripts/ask_gemini.py` | gemini.google.com |
| ChatGPT | `scripts/ask_chatgpt.py` | chatgpt.com |

## Workflow

### Step 1: Ensure Chrome is Running with CDP

If the script fails to connect (Chrome not running or no `--remote-debugging-port`), restart Chrome:

```bash
killall -9 chrome 2>/dev/null; sleep 1
{baseDir}/scripts/start_chrome.sh
```

The start script launches Chrome with `--remote-debugging-port=9222` and `--user-data-dir=~/.openclaw/workspace/chrome_profile`. Login sessions persist across restarts. If Chrome is already running without `--remote-debugging-port`, it must be killed first.

### Step 2: Choose Chatbot and Extract Query

**Choose chatbot**: Use the one the user names ("ask Gemini", "用 ChatGPT 查"). "GPT" means ChatGPT. Default to Gemini if unspecified.

**Extract query**: Strip only the trigger prefix. Do NOT rephrase, translate, summarize, or add context. Pass the rest verbatim:

| User says | Extracted query |
|-----------|----------------|
| "ask Gemini what is MCP protocol" | "what is MCP protocol" |
| "问一下 ChatGPT，transformer 的注意力机制怎么工作" | "transformer 的注意力机制怎么工作" |
| "用 GPT 查一下 React 19 有什么新特性" | "React 19 有什么新特性" |

### Step 3: Send the Query

```bash
# Gemini
{baseDir}/.venv/bin/python3 {baseDir}/scripts/ask_gemini.py "extracted query"

# ChatGPT
{baseDir}/.venv/bin/python3 {baseDir}/scripts/ask_chatgpt.py "extracted query"
```

| Flag | Description | Default |
|------|-------------|---------|
| `--port PORT` | Chrome CDP port | `9222` |
| `--timeout SECS` | Max wait for response | `120` |
| `--new-chat` | Force new chat session | `false` |
| `--json` | JSON output | `false` |

Parse the script output and present it to the user.

## Error Handling

| Error | Action |
|-------|--------|
| "Cannot connect to Chrome on port 9222" | `killall -9 chrome 2>/dev/null; sleep 1` then `{baseDir}/scripts/start_chrome.sh`, wait, retry |
| "You are not logged in" | Inform user to log in manually in the Chrome window |
| "Could not find input field" | Selectors may be outdated; inform user the script may need updating |
| Response timeout | Retry with `--timeout 300` |

## Rebuilding .venv

```bash
cd {baseDir} && rm -rf .venv && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
```
