#!/usr/bin/env bash

# Prompt color helpers. Wrap ANSI escapes in \[...\] so readline keeps the
# cursor position correct while editing long commands.
PROMPT_RESET="\\[${NC}\\]"
PROMPT_RED="\\[${RED}\\]"
PROMPT_GREEN="\\[${GREEN}\\]"
PROMPT_YELLOW="\\[${YELLOW}\\]"
PROMPT_BLUE="\\[${BLUE}\\]"
PROMPT_MAGENTA="\\[${MAGENTA}\\]"
PROMPT_CYAN="\\[${CYAN}\\]"
PROMPT_WHITE="\\[${WHITE}\\]"
PROMPT_DIM="\\[\033[2m\\]"
PROMPT_BOLD="\\[\033[1m\\]"

function prompt_segment {
    local color="$1"
    local icon="$2"
    local text="$3"

    [[ -n "$text" ]] || return
    printf '%b' "${PROMPT_DIM}│${PROMPT_RESET} ${color}${icon}${PROMPT_RESET} ${text} "
}

function get_username_hostname {
    local hostname

    hostname="$HOSTNAME"
    printf '%b' "${PROMPT_BLUE}${USER}${PROMPT_DIM}@${PROMPT_RESET}${PROMPT_BLUE}${hostname}${PROMPT_RESET}"
}

function get_working_dir {
    local home_dir="${HOME%/}"
    local working_dir="$PWD"

    case "$working_dir" in
    "$home_dir")
        working_dir="~"
        ;;
    "$home_dir"/*)
        working_dir="~/${working_dir#"$home_dir"/}"
        ;;
    esac

    printf '%b' "${PROMPT_BOLD}${PROMPT_CYAN}${working_dir}${PROMPT_RESET}"
}

function last_command_status {
    local status="${1:-$?}"

    if [ "$status" -eq 0 ]; then
        printf '%b' "${PROMPT_GREEN}✔${PROMPT_RESET}"
    else
        printf '%b' "${PROMPT_RED}✘ ${status}${PROMPT_RESET}"
    fi
}

function format_duration {
    local seconds="${1:-0}"
    local days=$((seconds / 86400))
    local remaining=$((seconds % 86400))
    local hours=$((remaining / 3600))
    local minutes
    local secs
    local output=""

    remaining=$((remaining % 3600))
    minutes=$((remaining / 60))
    secs=$((remaining % 60))

    ((days > 0)) && output+="${days}d"
    ((hours > 0)) && output+="${hours}h"
    ((minutes > 0)) && output+="${minutes}m"
    if ((secs > 0)) || [[ -z "$output" ]]; then
        output+="${secs}s"
    fi

    printf '%s\n' "$output"
}

function last_command_time {
    local formatted_time

    if [ "${LAST_COMMAND_TIME:-0}" -lt 0 ]; then
        export LAST_COMMAND_TIME=0
    fi

    formatted_time="$(format_duration "${LAST_COMMAND_TIME:-0}")"

    if [ "${LAST_COMMAND_TIME:-0}" -ge 10 ]; then
        printf '%b' "${PROMPT_RED}${formatted_time}${PROMPT_RESET}"
    else
        printf '%b' "${PROMPT_GREEN}${formatted_time}${PROMPT_RESET}"
    fi
}

function timer_stop {
    local history_entry
    local history_number
    local started_at
    local command_text

    history_entry="$(HISTTIMEFORMAT='%s ' builtin history 1 2>/dev/null)"
    if [ -z "$history_entry" ]; then
        export LAST_COMMAND_TIME=0
        return
    fi

    read -r history_number started_at command_text <<<"$history_entry"

    if [ -z "${PROMPT_LAST_HISTORY_ID:-}" ]; then
        export PROMPT_LAST_HISTORY_ID="$history_number"
        export LAST_COMMAND_TIME=0
        return
    fi

    if [ "$history_number" != "$PROMPT_LAST_HISTORY_ID" ] && [ -n "$started_at" ]; then
        export LAST_COMMAND_TIME=$((EPOCHSECONDS - started_at))
        if [ "$LAST_COMMAND_TIME" -lt 0 ]; then
            export LAST_COMMAND_TIME=0
        fi
        export PROMPT_LAST_HISTORY_ID="$history_number"
        return
    fi

    export LAST_COMMAND_TIME=0
}

function git_branch {
    local git_branch
    local dirty

    git_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    if [ -n "$git_branch" ]; then
        dirty="$(git status --porcelain 2>/dev/null | wc -l)"
        if [ "$dirty" -gt 0 ]; then
            printf '%b' "${PROMPT_RED}${git_branch} ✱${PROMPT_RESET}"
        else
            printf '%b' "${PROMPT_GREEN}${git_branch}${PROMPT_RESET}"
        fi
    fi
}

function prompt_command_output {
    if declare -F "$1" >/dev/null || command -v "$1" >/dev/null 2>&1; then
        "$@" 2>/dev/null
    fi
}

function build_prompt {
    local last_status="$1"
    local status_segment
    local time_segment
    local username_hostname_segment
    local working_dir_segment
    local git_segment
    local kubernetes_context_segment
    local kubernetes_namespace_segment
    local kubernetes_segment
    local current_time_segment
    local prompt_symbol
    KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
    status_segment="$(last_command_status "$last_status")"
    time_segment="$(last_command_time)"
    username_hostname_segment="$(get_username_hostname)"
    working_dir_segment="$(get_working_dir)"
    git_segment="$(git_branch)"
    kubernetes_context_segment="$(grep -o 'context: [^ ]*' "$KUBECONFIG" | cut -d' ' -f2 2>/dev/null)"
    kubernetes_namespace_segment="$(grep -o 'namespace: [^ ]*' "$KUBECONFIG" | cut -d' ' -f2 2>/dev/null)"
    printf -v current_time_segment '%(%H:%M:%S)T' -1

    if [[ -n "$kubernetes_context_segment" ]]; then
        kubernetes_segment="${PROMPT_BLUE}${kubernetes_context_segment}${PROMPT_RESET}${PROMPT_DIM}:${PROMPT_RESET}${PROMPT_CYAN}${kubernetes_namespace_segment:-default}${PROMPT_RESET}"
    fi

    if [ "$last_status" -eq 0 ]; then
        prompt_symbol="${PROMPT_GREEN}❯${PROMPT_RESET}"
    else
        prompt_symbol="${PROMPT_RED}❯${PROMPT_RESET}"
    fi

    printf -v PS1 '%b' \
        "${PROMPT_DIM}╭─${PROMPT_RESET} ${status_segment} ${PROMPT_DIM}${current_time_segment}${PROMPT_RESET} ${PROMPT_DIM}took${PROMPT_RESET} ${time_segment} $(prompt_segment "${PROMPT_BLUE}" "" "$username_hostname_segment")$(prompt_segment "${PROMPT_CYAN}" " " "$working_dir_segment")$(prompt_segment "${PROMPT_MAGENTA}" "" "$git_segment")$(prompt_segment "${PROMPT_BLUE}" "󱃾" "$kubernetes_segment")\n${PROMPT_DIM}╰─${PROMPT_RESET} ${prompt_symbol} "
}

function theme_prompt_command {
    local last_status=$?
    local saved_="${_}"

    timer_stop
    build_prompt "$last_status"

    _="${saved_}"
}

PROMPT_COMMAND="theme_prompt_command"
