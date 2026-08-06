#!/usr/bin/env bash

CONFIG="${CONFIG:-/usr/local/etc/machines.config}"
[ -f "$CONFIG" ] && source "$CONFIG"

get_cpu_idle() {
    vmstat 1 2 | tail -1 | awk '{print $15}'
}

get_net_bytes() {
    awk '
    /:/ {
        gsub(":", "", $1)
        if ($1 != "lo") {
            rx += $2
            tx += $10
        }
    }
    END { print rx, tx }' /proc/net/dev
}

# Write header once
if [ ! -f "$LOGFILE" ]; then
    echo "timestamp,cpu_idle,load1_pc,load5_pc,load15_pc,rx_bytes,tx_bytes" > "$LOGFILE"
fi

timestamp=$(date '+%Y-%m-%d %H:%M:%S')
ncores=$(nproc)

cpu_idle=$(get_cpu_idle)

read -r load1 load5 load15 _ < /proc/loadavg
read -r load1_pc load5_pc load15_pc < <(awk -v n="$ncores" \
    -v a="$load1" -v b="$load5" -v c="$load15" \
    'BEGIN {printf "%.2f %.2f %.2f", a/n, b/n, c/n}')

read -r rx tx < <(get_net_bytes)

echo "$timestamp,$cpu_idle,$load1_pc,$load5_pc,$load15_pc,$rx,$tx" >> "$LOGFILE"

tail -1 "$LOGFILE"
