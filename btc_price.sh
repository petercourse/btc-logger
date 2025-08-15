#!/bin/bash

# Define output file
OUTPUT="/root/BTCtrack/btc_price.txt"

# Fetch BTC price from CoinGecko
PRICE=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd" | \
        grep -o '"usd":[0-9.]*' | cut -d ':' -f2)

# Append timestamp and price to file
echo "$(date '+%Y-%m-%d %H:%M:%S') - BTC Price: \$${PRICE}" >> "$OUTPUT"
