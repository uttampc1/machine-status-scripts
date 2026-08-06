#!/usr/bin/env bash

CONFIG="${CONFIG:-/usr/local/etc/machines.config}"
[ -f "$CONFIG" ] && source "$CONFIG"

get_machine_status() {
    local out status reserved_by

    out=$(machine-status 2>/dev/null)

    if echo "$out" | grep -q "Reserved by"; then
        status="reserved"
        # extract the email after "Reserved by "
        reserved_by=$(echo "$out" | grep "Reserved by" \
            | sed -E 's/.*Reserved by[[:space:]]+([^ ]+).*/\1/')
    elif echo "$out" | grep -q "Machine is available"; then
        status="available"
        reserved_by=""
    else
        # couldn't determine — machine-status failed or unexpected output
        status="unknown"
        reserved_by=""
    fi

    echo "${status}|${reserved_by}"
}

notify_sysadmin() {
    local subject="$1" body="$2"

    if command -v mail >/dev/null 2>&1; then
        echo "$body" | mail -s "$subject" "$SYSADMIN_EMAIL"
    else
        local msg="[SYSADMIN-FALLBACK] $subject :: $body"
        echo "$msg" >&2                                    # visible to operator
        echo "$msg" >> "$SYSADMIN_LOG" 2>/dev/null \
            || echo "  (could not write to $SYSADMIN_LOG)" >&2
    fi
}

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

IFS='|' read -r status reserved_by < <(get_machine_status)
name=$(hostname)
case "$status" in
    available)
        echo "[$name] available — nothing to collect."
        if [ -f "$USAGE_LOG" ]; then
            /bin/rm -f "$USAGE_LOG"
	fi
        exit 0
        ;;
    reserved)
        ;;  # proceed
    *)
        notify_sysadmin "[$name] cannot determine reservation status (got: '$status')"
        exit 1
        ;;
esac

# Write header once
if [ ! -f "$USAGE_LOG" ]; then
    echo "timestamp,cpu_idle,load1_pc,load5_pc,load15_pc,rx_bytes,tx_bytes" > "$USAGE_LOG"
fi

timestamp=$(date '+%Y-%m-%d %H:%M:%S')
ncores=$(nproc)

cpu_idle=$(get_cpu_idle)

read -r load1 load5 load15 _ < /proc/loadavg
read -r load1_pc load5_pc load15_pc < <(awk -v n="$ncores" \
    -v a="$load1" -v b="$load5" -v c="$load15" \
    'BEGIN {printf "%.2f %.2f %.2f", a/n, b/n, c/n}')

read -r rx tx < <(get_net_bytes)

echo "$timestamp,$cpu_idle,$load1_pc,$load5_pc,$load15_pc,$rx,$tx" >> "$USAGE_LOG"

tail -1 "$USAGE_LOG"
