#!/usr/bin/env bash
# start_chrome.sh - Launch Chrome with remote debugging port for Playwright CDP connection
# Usage: ./start_chrome.sh [port]

set -euo pipefail

PORT="${1:-9222}"
GEMINI_URL="https://gemini.google.com"
USER_DATA_DIR="$HOME/.openclaw/workspace/chrome_profile"

# Detect Chrome binary
CHROME_BIN=""
for candidate in \
    "google-chrome" \
    "google-chrome-stable" \
    "google-chrome-beta" \
    "google-chrome-canary" \
    "chromium" \
    "chromium-browser" \
    "/usr/bin/google-chrome" \
    "/usr/bin/chromium-browser" \
    "/snap/bin/chromium" \
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "/Applications/Google Chrome Beta.app/Contents/MacOS/Google Chrome Beta" \
    "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary" \
    "/Applications/Chromium.app/Contents/MacOS/Chromium"; do
    if command -v "$candidate" &>/dev/null || [ -x "$candidate" ]; then
        CHROME_BIN="$candidate"
        break
    fi
done

if [ -z "$CHROME_BIN" ]; then
    echo "ERROR: Chrome/Chromium not found. Please install Google Chrome."
    exit 1
fi

# Check if port is already in use (Chrome may already be running with debug port)
if lsof -i ":$PORT" &>/dev/null 2>&1 || ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
    echo "Port $PORT is already in use."
    echo "Chrome may already be running with remote debugging enabled."
    echo "If not, close the process using port $PORT and try again."
    echo ""
    echo "To verify, open http://localhost:$PORT/json/version in your browser."
    exit 0
fi

echo "Starting Chrome with remote debugging on port $PORT..."
echo "Chrome binary: $CHROME_BIN"
echo ""
echo "IMPORTANT:"
echo "  1. Log in to your Google account in the opened Chrome window"
echo "  2. Navigate to $GEMINI_URL to verify access"
echo "  3. Keep this Chrome window open while using the web-chat skill"
echo ""

mkdir -p "$USER_DATA_DIR"

"$CHROME_BIN" \
    --remote-debugging-port="$PORT" \
    --user-data-dir="$USER_DATA_DIR" \
    --no-first-run \
    --no-default-browser-check \
    "$GEMINI_URL" &

echo "Chrome started (PID: $!)"
echo "CDP endpoint: http://localhost:$PORT"
