#!/usr/bin/env bash
# utils.sh — shared helpers for machine reservation tooling
# Source this: . /usr/local/lib/utils.sh   (or appropriate path)

# ---- Colors (guard against re-definition if already set) ----
: "${RESET:=$'\033[0m'}"
: "${BOLD:=$'\033[1m'}"
: "${RED:=$'\033[31m'}"
: "${YELLOW:=$'\033[33m'}"
: "${CYAN:=$'\033[36m'}"

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
