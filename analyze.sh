#!/usr/bin/env bash 

# ---- Load config (with fallback defaults) ----
CONFIG="${CONFIG:-/usr/local/etc/machines.config}"
[ -f "$CONFIG" ] && source "$CONFIG"

# Fallback defaults if config missing or incomplete
: "${DRY_RUN:=1}"
: "${USAGE_LOG:=/var/log/machine-usage.csv}"
: "${SYSADMIN_LOG:=/var/log/machine-sysadmin-alerts.log}"
: "${STATE_FILE:=/var/log/machine-usage-state.txt}"
: "${IDLE_CPU_THRESHOLD:=90}"
: "${LOAD_THRESHOLD:=0.20}"
: "${WINDOW_HOURS:=24}"
: "${IDLE_MAX_ACTIVE_PCT:=10}"
: "${MIN_POINTS_PER_WINDOW:=10}"
: "${STALE_HOURS:=24}"
: "${RELEASE_CONFIRM:=7}"
: "${INFO_PCT:=20}"
: "${SYSADMIN_EMAIL:=upawar}"

# ---- Shared awk preamble: reads CSV, classifies points, buckets into blocks ----
# Each function below is a thin wrapper around one awk pass.

is_weekend_ts() {
    local ts="$1"
    local dow
    dow=$(date -d "@$ts" +%u 2>/dev/null) || return 1
    [ "$dow" -ge 6 ]
}

classify() {
    [ -f "$USAGE_LOG" ] || return 0

    awk -F',' \
        -v cpu_thr="$IDLE_CPU_THRESHOLD" \
        -v load_thr="$LOAD_THRESHOLD" '
    NR==1 { next }
    NF < 7 { next }
    {
        ts = $1; e = ts; gsub(/[-:]/, " ", e); epoch = mktime(e)
        rx = $6; tx = $7
        if (NR > 2) { dt = epoch - pe; if (dt<=0) dt=1
            net = ((rx-prx)+(tx-ptx))/dt } else net = 0
        state = ($2 < cpu_thr || $3 >= load_thr) ? "ACTIVE" : "IDLE"
        printf "%s  %-6s  cpu_idle=%s  load1=%s  net=%.0f B/s\n", ts, state, $2, $3, net
        prx=rx; ptx=tx; pe=epoch
    }' "$USAGE_LOG"
}

blocks() {
    [ -f "$USAGE_LOG" ] || return 0
    awk -F',' \
        -v cpu_thr="$IDLE_CPU_THRESHOLD" -v load_thr="$LOAD_THRESHOLD" \
        -v max_pct="$IDLE_MAX_ACTIVE_PCT" -v win_h="$WINDOW_HOURS" \
        -v min_pts="$MIN_POINTS_PER_WINDOW" '
    function daynum(epoch,   cmd, d) {
        cmd = "date -d @" epoch " +%u"
        cmd | getline d
        close(cmd)
        return d + 0
    }

    NR==1 { next }
    NF < 7 { next }
    {
        ts=$1;
        e=ts;
        gsub(/[-:]/," ",e);
        epoch=mktime(e)

        active = ($2 < cpu_thr || $3 >= load_thr) ? 1 : 0

        ep[NR]=epoch;
        act[NR]=active

        if (epoch > newest) newest = epoch
    }
    END {
        win_sec = win_h*3600

        for (i=2;i<=NR;i++){
            b=int((newest-ep[i])/win_sec)
            total[b]++;
            if(act[i]) acnt[b]++;
            if (!(b in block_start) || ep[i] < block_start[b]) block_start[b] = ep[i]
            if(b>maxb) maxb=b
        }

        print "Block  Window(hrs ago)   Total  Active  Active%   Verdict"

        for (b=0;b<=maxb;b++){
            if(!(b in total)) continue

            t=total[b]+0;
            a=acnt[b]+0;
            pct=(t>0)?(a/t*100):0
            if (t<min_pts) {
                v="SKIP"
            } else if (pct>max_pct) {
                v="BUSY"
            } else {
                v="IDLE"
                dow = daynum(block_start[b])
                if (dow >= 6) v="WEEKEND_IDLE"
            }
            printf "%-6d %-17s %-6d %-7d %-8.1f %s\n", b, (b*win_h)"-"((b+1)*win_h), t, a, pct, v
        }
    }' "$USAGE_LOG"
}

streak() {
    [ -f "$USAGE_LOG" ] || return 0
    awk -F',' \
        -v cpu_thr="$IDLE_CPU_THRESHOLD" -v load_thr="$LOAD_THRESHOLD" \
        -v max_pct="$IDLE_MAX_ACTIVE_PCT" -v win_h="$WINDOW_HOURS" \
        -v min_pts="$MIN_POINTS_PER_WINDOW" '
    function daynum(epoch,   cmd, d) {
        cmd = "date -d @" epoch " +%u"
        cmd | getline d
        close(cmd)
        return d + 0
    }

    NR==1 { next }
    NF < 7 { next }
    {
        ts=$1; e=ts;
        gsub(/[-:]/," ",e);
        epoch=mktime(e)

        active = ($2 < cpu_thr || $3 >= load_thr) ? 1 : 0

        ep[NR]=epoch;
        act[NR]=active

        if (epoch > newest) newest = epoch
    }
    END {
        win_sec = win_h*3600

        for (i=2;i<=NR;i++){
            b=int((newest-ep[i])/win_sec)
            total[b]++;
            if(act[i]) acnt[b]++
            if (!(b in block_start) || ep[i] < block_start[b]) block_start[b] = ep[i]
            if(b > maxb) maxb=b
        }
        streak=0
        for (b=0;b<=maxb;b++){
            t=total[b]+0;
            a=acnt[b]+0;
            pct=(t>0)?(a/t*100):0
            if (t<min_pts) {
                v="SKIP"
            } else if (pct>max_pct) {
                v="BUSY"
            } else {
                v="IDLE"
                dow = daynum(block_start[b])
                if (dow >= 6) v="WEEKEND_IDLE"
            }

            if (v=="IDLE") {
                streak++
            } else if (v == "WEEKEND_IDLE") {
                continue
            } else {
                break
            }
        }
        print streak
    }' "$USAGE_LOG"
}

escalation_level() {
    local streak="$1"
    local n="$RELEASE_CONFIRM"
    local info_pct="$INFO_PCT"

    [ "$streak" -lt 1 ] && { echo "NONE"; return; }

    # Special compressed policies for very small RELEASE_CONFIRM
    if [ "$n" -le 1 ]; then
        if [ "$streak" -le 1 ]; then
          echo "INFO"
		    else 
          echo "CONFIRM"
		    fi 
        return
    fi

    if [ "$n" -eq 2 ]; then
        if [ "$streak" -ge 3 ]; then
          echo "CONFIRM"
        elif [ "$streak" -eq 2 ]; then
            echo "INFO"
        else
            echo "NONE"
        fi
        return
    fi

    if [ "$n" -eq 3 ]; then
        if [ "$streak" -ge 4 ]; then
          echo "CONFIRM"
        elif [ "$streak" -eq 3 ]; then
            echo "INFO"
        else
            echo "NONE"
        fi
        return
    fi

    if [ "$n" -eq 4 ]; then
        if [ "$streak" -ge 4 ]; then
            echo "CONFIRM"
        elif [ "$streak" -eq 3 ]; then
            echo "WARNING"
        elif [ "$streak" -eq 2 ]; then
            echo "INFO"
        else
            echo "NONE"
        fi
        return
    fi

    # General case: n > 4
		# Reaserve:
		# - last day for CONFIRM
		# - at least 1 day for WARNING
		# - at least 1 day for INFO
    # Use percentage-based silent window for the rest
    
		local silent_pct=40
    local max_silent=$(( n - 3 ))
    local silent_slots=$(( n * silent_pct / 100 ))
    if [ "$silent_slots" -lt 1 ]; then
	    silent_slots=1
	  fi
    if [ "$silent_slots" -gt "$max_silent" ]; then
		  silent_slots="$max_silent"
	  fi

    local remaining_after_silent=$(( n - silent_slots - 1 ))  # excluding CONFIRM day
    local info_slots=$(( n * info_pct / 100 ))
    [ "$info_slots" -lt 1 ] && info_slots=1

    # Leave at least 1 day for WARNING
    local max_info=$(( remaining_after_silent - 1 ))
    [ "$info_slots" -gt "$max_info" ] && info_slots="$max_info"

    local info_end=$(( silent_slots + info_slots ))

    if   [ "$streak" -ge "$n" ];            then echo "CONFIRM"
    elif [ "$streak" -le "$silent_slots" ]; then echo "NONE"
    elif [ "$streak" -le "$info_end" ];     then echo "INFO"
    else                                         echo "WARNING"
    fi
}

# staleness_check <logfile> [now_epoch]
staleness_check() {
    local logfile="$1"
    local now_epoch="${2:-$(date +%s)}"    # injectable for testing

    # Guard: file missing or has no data rows
    if [ ! -f "$logfile" ] || [ "$(wc -l < "$logfile")" -le 1 ]; then
        echo "STALE"
        return
    fi

    local latest_ts latest_epoch age_sec
    latest_ts=$(tail -1 "$logfile" | cut -d',' -f1)

    # convert "YYYY-MM-DD HH:MM:SS" → epoch
    local e="$latest_ts"; e="${e//[-:]/ }"
    latest_epoch=$(date -d "$latest_ts" +%s)

    age_sec=$(( now_epoch - latest_epoch ))

    if [ "$age_sec" -lt 0 ]; then
        echo "STALE"
    elif [ "$age_sec" -gt $(( STALE_HOURS * 3600 )) ]; then
        echo "STALE"
    else
        echo "HEALTHY"
    fi
}

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

release_eta_text() {
    local streak="$1"
    local remaining=$(( RELEASE_CONFIRM - streak ))

    [ "$remaining" -lt 1 ] && remaining=1

    if [ "$WINDOW_HOURS" -eq 24 ]; then
        if [ "$remaining" -eq 1 ]; then
            echo "next 1 day"
        else
            echo "next $remaining days"
        fi
    else
        local hrs=$(( remaining * WINDOW_HOURS ))
        if [ "$hrs" -eq 1 ]; then
            echo "next 1 hour"
        else
            echo "next $hrs hours"
        fi
    fi
}

# newest_timestamp — last (chronologically latest) record's timestamp
newest_timestamp() {
    tail -1 "$USAGE_LOG" | cut -d',' -f1
}

# ---- Notification placeholders (real email is a later task) ----
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

wall_message() {
    local banner="$1" machine="$2" user="$3" days="$4"
    write $user <<EOF
========================================
$banner
========================================
Machine : $machine
Reserved: $user
Idle for: $days day(s)

Please use the machine or release your
reservation if no longer needed.
========================================
EOF
}

notify_user() {
    local level="$1" machine="$2" user="$3" days="$4"

    local banner message eta
    eta=$(release_eta_text "$days")

    local motd=""
    case "$level" in
        INFO)
            banner="NOTICE: Machine Idle"
            message="According to current idle policy, this machine will be released in $eta if not used."
            motd="[INFO] reserved but idle for ${days} days"
            ;;
        WARNING)
            banner="WARNING: Machine Idle - Action Needed"
            message="According to current idle policy, this machine will be released in $eta if not used."
            motd="[WARNING] reserved but idle for ${days} days. This machine will be released in $eta if not used."
            ;;
        CONFIRM)
            banner="FINAL NOTICE: Reservation Will Be Released"
            message="According to current idle policy, this machine is now eligible for release."
            motd="[CONFIRM] reserved but idle for ${days} days. This machine will be released in 24 hours."
            ;;
    esac
    if [ "x$motd" != "x" ]; then
      # DB update: update_machine -m <mname> --motd ${motd}" 
      ./update_machine -m ${machine} --motd "${motd}"
    fi

    # wall_message $banner $machine $user $days
}

release_reservation() {
    local user="$1"
    local host; host=$(hostname)

    # Weekend gate: never release Sat/Sun (user may be away)
    local dow; dow=$(date +%u)     # 1=Mon ... 6=Sat, 7=Sun
    if [ "$dow" -ge 6 ]; then
        local msg="[$host] CONFIRM reached but release DEFERRED (weekend, dow=$dow). reserved_by=$user"
        echo "$msg" >&2
        echo "$msg" >> "$SYSADMIN_LOG" 2>/dev/null
        return 0
    fi

    if [ "$DRY_RUN" = "1" ]; then
        local msg="[DRY_RUN] would release $host (reserved_by=$user)"
        echo "$msg" >&2
        echo "$msg" >> "$SYSADMIN_LOG" 2>/dev/null
        return 0
    fi

    echo machine-release          # local, auto-hostname, always succeeds
    notify_sysadmin \
        "[$host] reservation RELEASED after idle timeout" \
        "was reserved_by=$user; escalation reached CONFIRM"
}

# ---- Main pipeline: the once-a-day analyzer ----
# main [machine_name]
main() {
    local name local status reserved_by
    name=$(hostname)

    # 1. Reservation gate
    IFS='|' read -r status reserved_by < <(get_machine_status)
    echo "STATUS is: $status"

    case "$status" in
        available)
            echo "[$name] available — nothing to do"
            return 0
            ;;
        reserved)
            if [ ! -f "$USAGE_LOG" ]; then
                echo "[$name] reserved but collection yet. — nothing to do"
                return 0
	    fi
            ;;  # proceed
        *)
            notify_sysadmin "[$name] cannot determine reservation status (got: '$status')"
            return 1
            ;;
    esac

    if [ ! -f "$USAGE_LOG" ]; then
        echo "[$name] usage log missing: $USAGE_LOG — nothing to analyze"
        exit 0
    fi

    # 2. Staleness gate (broken-cron detection)
    local health
    health=$(staleness_check "$USAGE_LOG")

    if [ "$health" = "STALE" ]; then
        notify_sysadmin \
            "[$name] usage collection may be broken" \
            "No fresh usage data (>${STALE_HOURS}h). reserved_by=$reserved_by"
        return 0
    fi

    # 2b. Dedup gate — guards ONLY the user ladder
    local current last
    current=$(newest_timestamp)
    last=$(cat "$STATE_FILE" 2>/dev/null)

    if [ "$current" = "$last" ]; then
        echo "[$name] no new data since last run ($last) — skipping user ladder"
        return 0
    fi

    # 3. Idle analysis + escalation
    local days level
    days=$(streak)
    level=$(escalation_level "$days")

    case "$level" in
        NONE)
            echo "[$name] reserved_by=$reserved_by idle_days=$days — no action"
            ;;
        INFO|WARNING)
            notify_user "$level" "$name" "$reserved_by" "$days"
            notify_sysadmin \
                "[$name] user notified: $level" \
                "reserved_by=$reserved_by idle_days=$days level=$level"
            ;;
        CONFIRM)
            notify_user CONFIRM "$name" "$reserved_by" "$days"
            notify_sysadmin \
                "[$name] reservation released: CONFIRM" \
                "reserved_by=$reserved_by idle_days=$days level=$level"
            release_reservation "$reserved_by"
            ;;
    esac

    # 4. Record that we've processed up to here (even if NONE)
    echo "$current" > "$STATE_FILE"
}

# ---- Dispatch ----
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  # $1 = logfile (optional; defaults to config USAGE_LOG)
  # $2 = subcommand
  USAGE_LOG="${1:-$USAGE_LOG}"

  case "${2:-run}" in
      classify) classify ;;
      blocks)   blocks ;;
      streak)   streak ;;
      escalate)
          days=$(streak)
          echo "Days=$days"
          level=$(escalation_level "$days")
          echo "idle_days=$days level=$level"
          ;;
      stale) staleness_check "$USAGE_LOG" "$3" ;;
      run)  main ;;
      *) echo "Usage: $0 [logfile] {classify|blocks|streak|escalate|stale|run}"; exit 1 ;;
  esac
fi
