#!/bin/bash

# Config
LOG_FILE="/root/BTCtrack/btc_price.txt"
ALERT_INDEX_FILE="/root/BTCtrack/alert_index.txt"
ACTIVE_ALERTS_FILE="/root/BTCtrack/active_alerts.txt"
REPO_NAME="petercourse/btc-logger"
TOKEN="your_github_token_here"

# Get latest price
latest_line=$(tail -n 1 "$LOG_FILE")
latest_price=$(echo "$latest_line" | awk -F '\\$' '{print $2}')

# Initialize files if missing
[[ ! -f "$ALERT_INDEX_FILE" ]] && echo "1" > "$ALERT_INDEX_FILE"
[[ ! -f "$ACTIVE_ALERTS_FILE" ]] && touch "$ACTIVE_ALERTS_FILE"

# Read initial price (first line)
initial_line=$(head -n 1 "$LOG_FILE")
initial_price=$(echo "$initial_line" | awk -F '\\$' '{print $2}')

# Check for new purchase alert
drop=$(echo "scale=2; (($latest_price - $initial_price) / $initial_price) * 100" | bc)
if (( $(echo "$drop <= -10" | bc -l) )); then
    index=$(cat "$ALERT_INDEX_FILE")
    echo "$index:$latest_price" >> "$ACTIVE_ALERTS_FILE"
    echo $((index + 1)) > "$ALERT_INDEX_FILE"

    curl -s -X POST https://api.github.com/repos/$REPO_NAME/issues \
      -H "Authorization: token $TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"title\": \"Purchase Alert $index\", \"body\": \"BTC dropped 10% from initial price. Entry price: \$${latest_price}\"}"
fi

# Check for sell alerts
while IFS=: read -r idx entry; do
    rise=$(echo "scale=2; (($latest_price - $entry) / $entry) * 100" | bc)
    if (( $(echo "$rise >= 10" | bc -l) )); then
        curl -s -X POST https://api.github.com/repos/$REPO_NAME/issues \
          -H "Authorization: token $TOKEN" \
          -H "Content-Type: application/json" \
          -d "{\"title\": \"Sell Alert $idx\", \"body\": \"BTC rose 10% from entry price \$${entry} to \$${latest_price}\"}"

        # Remove alert from active list
        grep -v "^$idx:" "$ACTIVE_ALERTS_FILE" > "${ACTIVE_ALERTS_FILE}.tmp"
        mv "${ACTIVE_ALERTS_FILE}.tmp" "$ACTIVE_ALERTS_FILE"
    fi
done < "$ACTIVE_ALERTS_FILE"
