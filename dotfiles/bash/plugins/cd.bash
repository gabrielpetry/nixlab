#!/usr/bin/env bash
# shellcheck disable=SC1091

set_zellij_tab() {
	# shellcheck disable=SC2312
	set +m
	[[ -z "${ZELLIJ}" ]] && return
	zellij action rename-tab "$(get_tab_name)"
	set -m
}

export _PREVIOUS_ENV_FILE=""
export _PREVIOUS_ENV_VARIABLES=""
export OLD_ENV
cd() {
	[[ -z "${OLD_ENV:-}" ]] && OLD_ENV="$(mktemp)"
	builtin cd "$@" || return
	# no zellijS

	set_zellij_tab
	tmux_tab_name_set
	load_env
}

load_env() {
	local git_root
	git_root="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
	msg=()
	if [[ "${VIRTUAL_ENV:-}" != "${git_root}/.venv" && -n "${VIRTUAL_ENV:-}" ]]; then
		msg+=("Deactivated virtual environment at ${VIRTUAL_ENV}")
		deactivate
	fi

	if [[ -d "${git_root}/.venv" ]]; then
		if [[ -z "${VIRTUAL_ENV:-}" ]]; then
			source "${git_root}/.venv/bin/activate"
			msg+=("Activated virtual environment at ${git_root}/.venv")
		fi
	fi

	if [[ -f "${git_root}/.env" ]]; then
		sourced="$(mktemp)"
		trap 'rm -f "${sourced}"' EXIT
		. "${git_root}/.env" >"${sourced}" 2>/dev/null
		msg+=("Sourced environment file at ${git_root}/.env")
		msg+=("$(cat "${sourced}")")
		[[ -z "${_PREVIOUS_ENV_FILE}" ]] && msg+=("Sourced environment file at ${git_root}/.env")
		_PREVIOUS_ENV_FILE="${git_root}/.env"
		_PREVIOUS_ENV_VARIABLES="$(grep -Eo '[A-Z_a-z]+=' "${git_root}/.env" | cut -d'=' -f1 || true)"
		if grep -Eo 'kubectx' "${git_root}/.env" -q; then
			_PREVIOUS_ENV_VARIABLES+=" KUBECONFIG"
		fi
	fi

	if [[ -n "${_PREVIOUS_ENV_FILE}" && "${_PREVIOUS_ENV_FILE}" != "${git_root}/.env" ]]; then

		for var in ${_PREVIOUS_ENV_VARIABLES}; do
			unset "${var}"
		done

		msg+=("Unset previous environment variables from ${_PREVIOUS_ENV_FILE}")
		msg+=("Loading previous environment from ${OLD_ENV}")
		# shellcheck disable=SC1090
		source "${OLD_ENV}"
		_PREVIOUS_ENV_FILE=""
		_PREVIOUS_ENV_VARIABLES=""
	fi

	if [[ ${#msg[@]} -gt 0 ]]; then
		yellow='\033[0;33m'
		nc='\033[0m' # No Color
		echo -e "${yellow}======= Environment Changes =======${nc}\n"
		printf '%s\n' "${msg[@]}"
		echo -e "${yellow}===================================${nc}\n"
	fi
}

reload_env() {
	unset "${_PREVIOUS_ENV_VARIABLES}"
	unset "${_PREVIOUS_ENV_FILE}"
	command -v deactivate >/dev/null 2>&1 && deactivate >/dev/null 2>&1
	load_env
}
