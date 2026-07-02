#!/usr/bin/env bash

# ==============================================================================
# AGENT INSTRUCTIONS: BASH-SIMPLE-DOC
# ==============================================================================
# This is a self-contained library for Bash script documentation and argument
# parsing. Agents can read this comment instead of parsing the entire file.
#
# INTERFACE (EXPORTED FUNCTIONS):
#   - Logging: `log_debug`, `log_info`, `log_warn`, `log_error`
#       (uses $LOG_LEVEL to filter, defaults to 'info', 'debug' activated with -v)
#   - Decorators: Used to document functions. Must be placed at the start of a
#     public function (before any other code).
#       `@doc "Description of the command"`
#       `@arg "--option|-o|var_name" "Description of option taking a value"`
#       `@arg "required" "--option|-o" "Description of required option"`
#       `@arg "nullable" "--option|-o" "Description of nullable option"`
#       `@arg "default=value" "--option|-o" "Description of option with default"`
#       `@flag "--flag|-f|flag_name" "Description of boolean flag"`
#       `@position "param_name" "Description of positional argument"`
#       `@example "example args"`
#       `@internal` - Marks the next decorator as internal-only in help.
#   - Parsing:
#       `@args "$@"` - Parses the arguments passed to a function using the
#       metadata defined by the decorators. Automatically assigns variables
#       named after the long signature (e.g., 'var_name' for --var-name)
#       or positional argument name.
#   - Entrypoint:
#       `@main "$@"` - Use this at the end of a script to automatically
#       route to public documented functions, handle --help, -v/--verbose,
#       and generate autocompletions.
#
# COMMON FLAGS (Handled by @main and @args):
#   - `-h`, `--help`: Prints command/script help.
#   - `--internal`: Only affects help output when combined with `--help`.
#   - `-v`, `--verbose`: Sets LOG_LEVEL=debug.
#   - `--version`: Prints the library version.
#   - `--completions bash`: Prints Bash completion script.
#
# HOW IT WORKS:
#   The library reads function source code using `declare -f` to find the
#   decorator calls and extract metadata. `@args` injects parsed values into
#   the function's scope dynamically.
# ==============================================================================

if [ -z "${BASH_VERSINFO+x}" ] || [ "${BASH_VERSINFO:-0}" -lt 5 ]; then
  printf '%s\n' 'bash simple doc requires Bash 5 or newer.' >&2
  exit 1
fi

declare -gA __BSD_BASE_FUNCTIONS=()
declare -ga __BSD_META_ARGS=()
declare -ga __BSD_META_ARGS_INTERNAL=()
declare -ga __BSD_META_FLAGS=()
declare -ga __BSD_META_FLAGS_INTERNAL=()
declare -ga __BSD_META_POSITIONS=()
declare -ga __BSD_META_POSITIONS_INTERNAL=()
declare -ga __BSD_META_EXAMPLES=()
declare -ga __BSD_META_EXAMPLES_INTERNAL=()
declare -g __BSD_META_DOC=""
declare -g __BSD_META_DOC_INTERNAL='false'
declare -g __BSD_DSL_PARSED=""
declare -g __BSD_DSL_REMAINDER=""
declare -g __BSD_SIG_LONG=""
declare -g __BSD_SIG_SHORT=""
declare -g __BSD_SIG_NAME=""
declare -g __BSD_RECORD_KEY=""
declare -g __BSD_RECORD_VALUE=""
declare -g __BSD_ARG_SIGNATURE=""
declare -g __BSD_ARG_DESCRIPTION=""
declare -g __BSD_ARG_REQUIRED='false'
declare -g __BSD_ARG_NULLABLE='false'
declare -g __BSD_ARG_HAS_DEFAULT='false'
declare -g __BSD_ARG_DEFAULT=""
declare -g __BSD_LAST_EVENT=""
declare -gr __BSD_LIBRARY_NAME='bash-simple-doc'
declare -gr __BSD_VERSION='0.1.0'

function __bsd_log_level_num {
  case "$1" in
  debug) printf '10\n' ;;
  info) printf '20\n' ;;
  warn) printf '30\n' ;;
  error) printf '40\n' ;;
  *) printf '20\n' ;;
  esac
}

function __bsd_log {
  local level=$1
  shift

  local wanted_level current_level stream color reset label level_num
  wanted_level=${LOG_LEVEL:-info}
  current_level=$level
  level_num=$(__bsd_log_level_num "$current_level")
  wanted_level=$(__bsd_log_level_num "$wanted_level")

  if ((level_num < wanted_level)); then
    return 0
  fi

  label=${level^^}
  stream=1
  color=''
  reset=''

  case "$level" in
  debug) color='\033[36m' ;;
  info) color='\033[34m' ;;
  warn)
    color='\033[33m'
    stream=2
    ;;
  error)
    color='\033[31m'
    stream=2
    ;;
  esac

  if [[ ! -t $stream || -n ${NO_COLOR-} ]]; then
    color=''
    reset=''
  else
    reset='\033[0m'
  fi

  local message
  if (($# == 1)); then
    message=$1
  else
    # shellcheck disable=SC2059
    printf -v message "$@"
  fi

  if [[ $message != *$'\n' ]]; then
    message+=$'\n'
  fi

  if ((stream == 1)); then
    printf '%b[%s]%b %s' "$color" "$label" "$reset" "$message"
  else
    printf '%b[%s]%b %s' "$color" "$label" "$reset" "$message" >&2
  fi
}

function log_debug {
  (($# > 0)) || log_fail 'log_debug requires a message'
  __bsd_log debug "$@"
}

function log_info {
  (($# > 0)) || log_fail 'log_info requires a message'
  __bsd_log info "$@"
}

function log_warn {
  (($# > 0)) || log_fail 'log_warn requires a message'
  __bsd_log warn "$@"
}

function log_error {
  (($# > 0)) || log_fail 'log_error requires a message'
  __bsd_log error "$@"
}

function log_fail {
  local message='log_fail requires a message'

  if (($# > 0)); then
    if (($# == 1)); then
      message=$1
    else
      # shellcheck disable=SC2059
      printf -v message "$@"
    fi

    __bsd_log error "$message"
  else
    printf '[ERROR] %s\n' "$message" >&2
  fi

  exit 1
}

function __bsd_reset_metadata {
  __BSD_META_DOC=""
  __BSD_META_DOC_INTERNAL='false'
  __BSD_META_ARGS=()
  __BSD_META_ARGS_INTERNAL=()
  __BSD_META_FLAGS=()
  __BSD_META_FLAGS_INTERNAL=()
  __BSD_META_POSITIONS=()
  __BSD_META_POSITIONS_INTERNAL=()
  __BSD_META_EXAMPLES=()
  __BSD_META_EXAMPLES_INTERNAL=()
}

function __bsd_metadata_visible {
  local include_internal=$1
  local is_internal=$2

  [[ $is_internal != true || $include_internal == true ]]
}

function __bsd_split_record {
  local record=$1

  __BSD_RECORD_KEY=${record%%$'\t'*}
  if [[ $record == *$'\t'* ]]; then
    __BSD_RECORD_VALUE=${record#*$'\t'}
  else
    __BSD_RECORD_VALUE=''
  fi
}

function __bsd_pack_arg_record {
  local signature=$1
  local description=${2-}
  local required=${3-false}
  local nullable=${4-false}
  local has_default=${5-false}
  local default_value=${6-}

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$signature" "$description" "$required" "$nullable" "$has_default" "$default_value"
}

function __bsd_parse_arg_record {
  local record=$1
  local fields=()

  IFS=$'\t' read -r -a fields <<<"$record"

  __BSD_ARG_SIGNATURE=${fields[0]-}
  __BSD_ARG_DESCRIPTION=${fields[1]-}
  __BSD_ARG_REQUIRED=${fields[2]-false}
  __BSD_ARG_NULLABLE=${fields[3]-false}
  __BSD_ARG_HAS_DEFAULT=${fields[4]-false}
  __BSD_ARG_DEFAULT=${fields[5]-}
}

function __bsd_is_blank_value {
  local value=${1-}

  [[ $value =~ ^[[:space:]]*$ ]]
}

function __bsd_fail_metadata {
  local function_name=$1
  local message=$2

  log_error 'Invalid metadata in %s: %s' "$function_name" "$message"
  return 65
}

function __bsd_parse_arg_metadata {
  local meta_string=$1
  local signature=$2
  local function_name=$3
  local token
  local has_default='false'
  local required='false'
  local nullable='false'
  local default_value=''
  local -a tokens=()

  __BSD_ARG_REQUIRED='false'
  __BSD_ARG_NULLABLE='false'
  __BSD_ARG_HAS_DEFAULT='false'
  __BSD_ARG_DEFAULT=''

  [[ -n $meta_string ]] || return 0

  IFS=',' read -r -a tokens <<<"$meta_string"
  for token in "${tokens[@]}"; do
    case "$token" in
    required)
      required='true'
      ;;
    nullable)
      nullable='true'
      ;;
    default=*)
      if [[ $has_default == true ]]; then
        __bsd_fail_metadata "$function_name" "@arg metadata for $signature has duplicate default values"
        return $?
      fi
      has_default='true'
      default_value=${token#default=}
      ;;
    '')
      __bsd_fail_metadata "$function_name" "@arg metadata for $signature contains an empty token"
      return $?
      ;;
    *)
      __bsd_fail_metadata "$function_name" "@arg metadata for $signature has unknown token: $token"
      return $?
      ;;
    esac
  done

  if [[ $required == true && $nullable == true ]]; then
    __bsd_fail_metadata "$function_name" "@arg metadata for $signature cannot combine required and nullable"
    return $?
  fi

  if [[ $required == true && $has_default == true ]]; then
    __bsd_fail_metadata "$function_name" "@arg metadata for $signature cannot combine required and default"
    return $?
  fi

  __BSD_ARG_REQUIRED=$required
  __BSD_ARG_NULLABLE=$nullable
  __BSD_ARG_HAS_DEFAULT=$has_default
  __BSD_ARG_DEFAULT=$default_value
}

function __bsd_unquote_dsl_arg {
  local input=$1
  local parsed='' char next_char
  local index=0

  input=${input#"${input%%[![:space:]]*}"}

  __BSD_DSL_PARSED=''
  __BSD_DSL_REMAINDER=''

  if [[ -z $input ]]; then
    return 1
  fi

  if [[ $input == '"'* ]]; then
    input=${input:1}
    while ((index < ${#input})); do
      char=${input:index:1}
      next_char=${input:index+1:1}

      if [[ $char == $'\\' && $next_char == '"' ]]; then
        parsed+='"'
        ((index += 2))
        continue
      fi

      if [[ $char == '"' ]]; then
        ((index++))
        break
      fi

      parsed+=$char
      ((index++))
    done

    __BSD_DSL_PARSED=$parsed
    input=${input:index}
    __BSD_DSL_REMAINDER=${input#"${input%%[![:space:]]*}"}
  else
    __BSD_DSL_PARSED=${input%% *}
    if [[ $input == *' '* ]]; then
      __BSD_DSL_REMAINDER=${input#* }
    fi
  fi

  return 0
}

function __bsd_parse_option_signature {
  local signature=$1
  local -a parts=()
  local part normalized

  __BSD_SIG_LONG=''
  __BSD_SIG_SHORT=''
  __BSD_SIG_NAME=''

  IFS='|' read -r -a parts <<<"$signature"
  for part in "${parts[@]}"; do
    case "$part" in
    --*) __BSD_SIG_LONG=$part ;;
    -*) __BSD_SIG_SHORT=$part ;;
    esac
  done

  if [[ -n $__BSD_SIG_LONG ]]; then
    normalized=${__BSD_SIG_LONG#--}
  elif [[ -n $__BSD_SIG_SHORT ]]; then
    normalized=${__BSD_SIG_SHORT#-}
  else
    return 1
  fi

  __BSD_SIG_NAME=${normalized//-/_}
  return 0
}

function __bsd_option_label {
  local signature=$1
  local needs_value=$2

  __bsd_parse_option_signature "$signature" || return 1

  if [[ -n $__BSD_SIG_SHORT && -n $__BSD_SIG_LONG ]]; then
    if [[ $needs_value == true ]]; then
      printf '%s, %s VALUE\n' "$__BSD_SIG_SHORT" "$__BSD_SIG_LONG"
    else
      printf '%s, %s\n' "$__BSD_SIG_SHORT" "$__BSD_SIG_LONG"
    fi
    return 0
  fi

  if [[ -n $__BSD_SIG_LONG ]]; then
    if [[ $needs_value == true ]]; then
      printf '%s VALUE\n' "$__BSD_SIG_LONG"
    else
      printf '%s\n' "$__BSD_SIG_LONG"
    fi
    return 0
  fi

  if [[ $needs_value == true ]]; then
    printf '%s VALUE\n' "$__BSD_SIG_SHORT"
  else
    printf '%s\n' "$__BSD_SIG_SHORT"
  fi
}

function __bsd_usage_token {
  local signature=$1
  local needs_value=$2
  local preferred

  __bsd_parse_option_signature "$signature" || return 1

  if [[ -n $__BSD_SIG_LONG ]]; then
    preferred=$__BSD_SIG_LONG
  else
    preferred=$__BSD_SIG_SHORT
  fi

  if [[ $needs_value == true ]]; then
    printf '[%s VALUE]\n' "$preferred"
  else
    printf '[%s]\n' "$preferred"
  fi
}

function __bsd_extract_dsl_lines {
  local function_name=$1
  local source line trimmed started first_line

  source=$(declare -f "$function_name") || return 1
  started=0
  first_line=1

  while IFS= read -r line; do
    if ((first_line)); then
      first_line=0
      continue
    fi

    trimmed=${line#"${line%%[![:space:]]*}"}
    [[ $trimmed == \{* ]] && continue
    [[ $trimmed == '}' ]] && break

    if [[ -z $trimmed || $trimmed == \#* ]]; then
      continue
    fi

    case "$trimmed" in
    @internal | @internal\;)
      started=1
      printf '%s\n' "$trimmed"
      ;;
    @doc\ * | @arg\ * | @flag\ * | @position\ * | @example\ *)
      started=1
      printf '%s\n' "$trimmed"
      ;;
    @args | @args\ *)
      return 0
      ;;
    *)
      if ((started)); then
        return 0
      fi
      return 1
      ;;
    esac
  done <<<"$source"

  ((started))
}

function __bsd_load_metadata {
  local function_name=$1
  local line cmd rest arg1 arg2 description meta_string is_internal='false'
  local -a dsl_lines=()

  declare -F "$function_name" >/dev/null || return 1

  __bsd_reset_metadata
  mapfile -t dsl_lines < <(__bsd_extract_dsl_lines "$function_name")
  ((${#dsl_lines[@]} > 0)) || return 1

  for line in "${dsl_lines[@]}"; do
    if [[ $line == @internal || $line == '@internal;' ]]; then
      is_internal='true'
      continue
    fi

    cmd=${line%% *}
    rest=${line#* }

    case "$cmd" in
    @doc)
      __bsd_unquote_dsl_arg "$rest"
      __BSD_META_DOC=$__BSD_DSL_PARSED
      __BSD_META_DOC_INTERNAL=$is_internal
      ;;
    @arg)
      __bsd_unquote_dsl_arg "$rest"
      arg1=$__BSD_DSL_PARSED

      meta_string=''
      description=''
      if [[ $arg1 == -* ]]; then
        arg2=$arg1
        if [[ -n $__BSD_DSL_REMAINDER ]]; then
          __bsd_unquote_dsl_arg "$__BSD_DSL_REMAINDER"
          description=$__BSD_DSL_PARSED
        fi
      else
        meta_string=$arg1
        if [[ -z $__BSD_DSL_REMAINDER ]]; then
          __bsd_fail_metadata "$function_name" '@arg requires an option signature'
          return $?
        fi

        __bsd_unquote_dsl_arg "$__BSD_DSL_REMAINDER"
        arg2=$__BSD_DSL_PARSED
        if [[ $arg2 != -* ]]; then
          __bsd_fail_metadata "$function_name" "@arg metadata must be followed by an option signature, got: $arg2"
          return $?
        fi

        if [[ -n $__BSD_DSL_REMAINDER ]]; then
          __bsd_unquote_dsl_arg "$__BSD_DSL_REMAINDER"
          description=$__BSD_DSL_PARSED
        fi
      fi

      __bsd_parse_arg_metadata "$meta_string" "$arg2" "$function_name" || return $?
      __BSD_META_ARGS+=("$(__bsd_pack_arg_record "$arg2" "$description" "$__BSD_ARG_REQUIRED" "$__BSD_ARG_NULLABLE" "$__BSD_ARG_HAS_DEFAULT" "$__BSD_ARG_DEFAULT")")
      __BSD_META_ARGS_INTERNAL+=("$is_internal")
      ;;
    @flag)
      __bsd_unquote_dsl_arg "$rest"
      arg1=$__BSD_DSL_PARSED
      __bsd_unquote_dsl_arg "$__BSD_DSL_REMAINDER"
      __BSD_META_FLAGS+=("$arg1"$'\t'"$__BSD_DSL_PARSED")
      __BSD_META_FLAGS_INTERNAL+=("$is_internal")
      ;;
    @position)
      __bsd_unquote_dsl_arg "$rest"
      arg1=$__BSD_DSL_PARSED
      __bsd_unquote_dsl_arg "$__BSD_DSL_REMAINDER"
      __BSD_META_POSITIONS+=("$arg1"$'\t'"$__BSD_DSL_PARSED")
      __BSD_META_POSITIONS_INTERNAL+=("$is_internal")
      ;;
    @example)
      __bsd_unquote_dsl_arg "$rest"
      __BSD_META_EXAMPLES+=("$__BSD_DSL_PARSED")
      __BSD_META_EXAMPLES_INTERNAL+=("$is_internal")
      ;;
    esac

    is_internal='false'
  done

  [[ -n $__BSD_META_DOC ]]
}

function __bsd_is_public_command {
  local function_name=$1
  local status

  [[ -z ${__BSD_BASE_FUNCTIONS[$function_name]-} ]] || return 1
  [[ $function_name != @* ]] || return 1

  __bsd_load_metadata "$function_name" >/dev/null
  status=$?
  if ((status > 1)); then
    return "$status"
  fi

  return "$status"
}

function __bsd_collect_public_commands {
  local array_name=$1
  local function_name
  local status
  local -n __bsd_output_ref=$array_name

  __bsd_output_ref=()
  while read -r _ _ function_name; do
    if __bsd_is_public_command "$function_name"; then
      __bsd_output_ref+=("$function_name")
    else
      status=$?
      if ((status > 1)); then
        return "$status"
      fi
    fi
  done < <(declare -F)
}

function __bsd_print_public_commands {
  local function_name
  local -a commands=()

  __bsd_collect_public_commands commands || return $?
  for function_name in "${commands[@]}"; do
    printf '%s\n' "$function_name"
  done
}

function __bsd_print_root_completion_words {
  printf '%s\n' '-h' '--help' '-v' '--verbose' '--completions' '--version'
  __bsd_print_public_commands
}

function __bsd_print_version {
  log_debug '%s version %s' "$__BSD_LIBRARY_NAME" "$__BSD_VERSION"
  printf '%s %s\n' "$__BSD_LIBRARY_NAME" "$__BSD_VERSION"
}

function __bsd_assign_variable {
  local variable_name=$1
  local value=$2

  case "$variable_name" in
  '' | *[!a-zA-Z0-9_]*)
    log_error "Invalid variable name: $variable_name"
    return 1
    ;;
  PATH | IFS | HOME | SHELL | USER | UID | EUID | BASH | BASH_* | SHELLOPTS | BASHOPTS | COMP_* | FUNCNAME | __BSD_*)
    log_error "Refusing to assign to reserved variable: $variable_name"
    return 1
    ;;
  esac

  printf -v "$variable_name" '%s' "$value"
}

function __bsd_find_option_record {
  local token=$1
  local array_name=$2
  local record
  local -n records=$array_name

  for record in "${records[@]}"; do
    if [[ $array_name == '__BSD_META_ARGS' ]]; then
      __bsd_parse_arg_record "$record"
      __BSD_RECORD_KEY=$__BSD_ARG_SIGNATURE
      __bsd_parse_option_signature "$__BSD_ARG_SIGNATURE" || continue
    else
      __bsd_split_record "$record"
      __bsd_parse_option_signature "$__BSD_RECORD_KEY" || continue
    fi

    if [[ $token == "$__BSD_SIG_LONG" || $token == "$__BSD_SIG_SHORT" ]]; then
      return 0
    fi
  done

  return 1
}

function __bsd_print_command_options {
  local function_name=$1
  local record

  if ! __bsd_load_metadata "$function_name"; then
    return 1
  fi

  printf '%s\n' '-h' '--help' '-v' '--verbose'
  for record in "${__BSD_META_ARGS[@]}"; do
    __bsd_parse_arg_record "$record"
    __bsd_parse_option_signature "$__BSD_ARG_SIGNATURE" || continue
    [[ -n $__BSD_SIG_SHORT ]] && printf '%s\n' "$__BSD_SIG_SHORT"
    [[ -n $__BSD_SIG_LONG ]] && printf '%s\n' "$__BSD_SIG_LONG"
  done
  for record in "${__BSD_META_FLAGS[@]}"; do
    __bsd_split_record "$record"
    __bsd_parse_option_signature "$__BSD_RECORD_KEY" || continue
    [[ -n $__BSD_SIG_SHORT ]] && printf '%s\n' "$__BSD_SIG_SHORT"
    [[ -n $__BSD_SIG_LONG ]] && printf '%s\n' "$__BSD_SIG_LONG"
  done
}

function __bsd_collect_completion_words {
  local printer_name=$1
  local array_name=$2
  # shellcheck disable=SC2178
  local -n __bsd_output_ref=$array_name

  mapfile -t __bsd_output_ref < <("$printer_name")
}

function __bsd_collect_command_completion_words {
  local function_name=$1
  local array_name=$2
  # shellcheck disable=SC2178
  local -n __bsd_output_ref=$array_name

  mapfile -t __bsd_output_ref < <(__bsd_print_command_options "$function_name")
}

function __bsd_collect_value_expecting_options {
  local function_name=$1
  local array_name=$2
  local record
  # shellcheck disable=SC2178
  local -n __bsd_output_ref=$array_name

  __bsd_output_ref=()

  __bsd_load_metadata "$function_name" || return 1

  for record in "${__BSD_META_ARGS[@]}"; do
    __bsd_parse_arg_record "$record"
    __bsd_parse_option_signature "$__BSD_ARG_SIGNATURE" || continue
    [[ -n $__BSD_SIG_SHORT ]] && __bsd_output_ref+=("$__BSD_SIG_SHORT")
    [[ -n $__BSD_SIG_LONG ]] && __bsd_output_ref+=("$__BSD_SIG_LONG")
  done
}

function __bsd_option_expects_value {
  local function_name=$1
  local token=$2

  [[ -n $token ]] || return 1
  __bsd_load_metadata "$function_name" || return 1
  __bsd_find_option_record "$token" '__BSD_META_ARGS'
}

function __bsd_arg_annotations {
  local required=$1
  local nullable=$2
  local has_default=$3
  local default_value=$4
  local annotations=''

  if [[ $required == true ]]; then
    annotations+=' (required)'
  fi

  if [[ $nullable == true ]]; then
    annotations+=' (nullable)'
  fi

  if [[ $has_default == true ]]; then
    annotations+=" (default: $default_value)"
  fi

  printf '%s\n' "$annotations"
}

function __bsd_identifier {
  local value=$1

  value=${value//[^[:alnum:]_]/_}
  if [[ $value == [0-9]* ]]; then
    value=_$value
  fi

  printf '%s\n' "$value"
}

function __bsd_resolve_path {
  local path=$1
  local dir base resolved

  if [[ $path == */* ]]; then
    dir=${path%/*}
    base=${path##*/}
    [[ $dir == "$path" ]] && dir='.'
    [[ -z $dir ]] && dir='/'

    if resolved=$(builtin cd "$dir" 2>/dev/null && printf '%s/%s\n' "$(pwd -P)" "$base"); then
      printf '%s\n' "$resolved"
      return 0
    fi

    printf '%s/%s\n' "$(pwd -P)" "$path"
    return 0
  fi

  if resolved=$(command -v "$path" 2>/dev/null); then
    printf '%s\n' "$resolved"
    return 0
  fi

  printf '%s/%s\n' "$(pwd -P)" "$path"
}

function __bsd_print_bash_completions {
  local script_name=$1
  local script_source=$2
  local script_invocation=${3-}
  local function_suffix completion_function target quoted_target
  local quoted_word quoted_key quoted_value
  local command option expects_value_key
  local root_words_var options_var expects_value_var
  local -a targets=() root_words=() command_names=() command_options=() value_options=()

  function_suffix=$(__bsd_identifier "$script_name")
  completion_function="__bsd_complete_${function_suffix}"
  root_words_var="__bsd_root_words_${function_suffix}"
  options_var="__bsd_options_by_command_${function_suffix}"
  expects_value_var="__bsd_expects_value_${function_suffix}"

  targets=("$script_name" "$(__bsd_resolve_path "$script_source")")
  if [[ -n $script_invocation && $script_invocation != "$script_name" && $script_invocation != "${targets[1]}" ]]; then
    targets+=("$script_invocation")
  fi

  __bsd_collect_completion_words '__bsd_print_root_completion_words' 'root_words'
  local -a public_commands=()
  __bsd_collect_public_commands public_commands || return $?
  command_names=("${public_commands[@]}")

  cat <<EOF
declare -a $root_words_var=(
EOF

  for quoted_word in "${root_words[@]}"; do
    printf '  %q\n' "$quoted_word"
  done

  cat <<EOF
)
declare -A $options_var=()
declare -A $expects_value_var=()

EOF

  for command in "${command_names[@]}"; do
    __bsd_collect_command_completion_words "$command" 'command_options'
    quoted_value=''
    if ((${#command_options[@]} > 0)); then
      printf -v quoted_value '%s' "${command_options[*]}"
    fi

    printf -v quoted_key '%q' "$command"
    printf -v quoted_value '%q' "$quoted_value"
    printf '%s[%s]=%s\n' "$options_var" "$quoted_key" "$quoted_value"

    __bsd_collect_value_expecting_options "$command" 'value_options'
    for option in "${value_options[@]}"; do
      expects_value_key="$command|$option"
      printf -v quoted_key '%q' "$expects_value_key"
      printf '%s[%s]=1\n' "$expects_value_var" "$quoted_key"
    done
  done

  cat <<EOF
function $completion_function {
	local cur prev command suggestions expects_value_key
	COMPREPLY=()
	cur=
	prev=
	command=

	if (( COMP_CWORD < \${#COMP_WORDS[@]} )); then
		cur=\${COMP_WORDS[COMP_CWORD]}
	fi

	if (( COMP_CWORD > 0 )); then
		prev=\${COMP_WORDS[COMP_CWORD-1]}
	fi

	if (( COMP_CWORD == 1 )); then
		mapfile -t COMPREPLY < <(compgen -W "\${${root_words_var}[*]}" -- "\$cur")
		return 0
	fi

	if [[ \${COMP_WORDS[1]} == --completions ]]; then
		if (( COMP_CWORD == 2 )); then
			mapfile -t COMPREPLY < <(compgen -W "bash" -- "\$cur")
		fi
		return 0
	fi

	command=\${COMP_WORDS[1]}
	if [[ \$command == -h || \$command == --help || \$command == -v || \$command == --verbose ]]; then
		return 0
	fi

	expects_value_key="\$command|\$prev"
	if (( COMP_CWORD > 2 )) && [[ -n \${${expects_value_var}[\$expects_value_key]-} ]]; then
		compopt -o default 2>/dev/null
		return 0
	fi

	if [[ \$cur == -* ]]; then
		suggestions=\${${options_var}[\$command]-}
		mapfile -t COMPREPLY < <(compgen -W "\$suggestions" -- "\$cur")
		return 0
	fi

	compopt -o default 2>/dev/null
}
EOF

  for target in "${targets[@]}"; do
    printf -v quoted_target '%q' "$target"
    printf 'complete -o default -F %s %s\n' "$completion_function" "$quoted_target"
  done
}

function __bsd_complete {
  local action=${1-}
  local status

  shift || true

  case "$action" in
  root)
    (($# == 0)) || return 64
    __bsd_print_root_completion_words
    ;;
  commands)
    (($# == 0)) || return 64
    __bsd_print_public_commands
    ;;
  options)
    (($# == 1)) || return 64
    if __bsd_is_public_command "$1"; then
      :
    else
      status=$?
      if ((status > 1)); then
        return "$status"
      fi
      return 64
    fi
    __bsd_print_command_options "$1"
    ;;
  expects-value)
    (($# == 2)) || return 64
    if __bsd_is_public_command "$1"; then
      :
    else
      status=$?
      if ((status > 1)); then
        return "$status"
      fi
      return 64
    fi
    __bsd_option_expects_value "$1" "$2"
    ;;
  is-command)
    (($# == 1)) || return 64
    __bsd_is_public_command "$1"
    ;;
  *)
    return 64
    ;;
  esac
}

function __bsd_print_command_help {
  local function_name=$1
  local script_name=${2:-${0##*/}}
  local include_internal=${3:-false}
  local record label summary internal_flag annotations status
  local index has_visible_positions=0 has_visible_examples=0

  if __bsd_load_metadata "$function_name"; then
    :
  else
    status=$?
    if ((status > 1)); then
      return "$status"
    fi

    log_error "Unknown documented command: $function_name"
    return 1
  fi

  printf 'Usage: %s %s' "$script_name" "$function_name"
  for index in "${!__BSD_META_ARGS[@]}"; do
    internal_flag=${__BSD_META_ARGS_INTERNAL[$index]}
    __bsd_metadata_visible "$include_internal" "$internal_flag" || continue
    record=${__BSD_META_ARGS[$index]}
    __bsd_parse_arg_record "$record"
    printf ' %s' "$(if [[ $__BSD_ARG_REQUIRED == true ]]; then __bsd_option_label "$__BSD_ARG_SIGNATURE" true; else __bsd_usage_token "$__BSD_ARG_SIGNATURE" true; fi)"
  done
  for index in "${!__BSD_META_FLAGS[@]}"; do
    internal_flag=${__BSD_META_FLAGS_INTERNAL[$index]}
    __bsd_metadata_visible "$include_internal" "$internal_flag" || continue
    record=${__BSD_META_FLAGS[$index]}
    __bsd_split_record "$record"
    printf ' %s' "$(__bsd_usage_token "$__BSD_RECORD_KEY" false)"
  done
  for index in "${!__BSD_META_POSITIONS[@]}"; do
    internal_flag=${__BSD_META_POSITIONS_INTERNAL[$index]}
    __bsd_metadata_visible "$include_internal" "$internal_flag" || continue
    record=${__BSD_META_POSITIONS[$index]}
    __bsd_split_record "$record"
    printf ' <%s>' "$__BSD_RECORD_KEY"
  done
  if __bsd_metadata_visible "$include_internal" "$__BSD_META_DOC_INTERNAL" && [[ -n $__BSD_META_DOC ]]; then
    printf '\n\n%s\n' "$__BSD_META_DOC"
  else
    printf '\n'
  fi

  printf '\nOptions:\n'
  printf '  %-24s %s\n' '-h, --help' 'Show this help message'
  printf '  %-24s %s\n' '-v, --verbose' 'Enable verbose logging (debug level)'
  for index in "${!__BSD_META_ARGS[@]}"; do
    internal_flag=${__BSD_META_ARGS_INTERNAL[$index]}
    __bsd_metadata_visible "$include_internal" "$internal_flag" || continue
    record=${__BSD_META_ARGS[$index]}
    __bsd_parse_arg_record "$record"
    label=$(__bsd_option_label "$__BSD_ARG_SIGNATURE" true)
    annotations=$(__bsd_arg_annotations "$__BSD_ARG_REQUIRED" "$__BSD_ARG_NULLABLE" "$__BSD_ARG_HAS_DEFAULT" "$__BSD_ARG_DEFAULT")
    printf '  %-24s %s%s\n' "$label" "$__BSD_ARG_DESCRIPTION" "$annotations"
  done
  for index in "${!__BSD_META_FLAGS[@]}"; do
    internal_flag=${__BSD_META_FLAGS_INTERNAL[$index]}
    __bsd_metadata_visible "$include_internal" "$internal_flag" || continue
    record=${__BSD_META_FLAGS[$index]}
    __bsd_split_record "$record"
    label=$(__bsd_option_label "$__BSD_RECORD_KEY" false)
    printf '  %-24s %s\n' "$label" "$__BSD_RECORD_VALUE"
  done

  for index in "${!__BSD_META_POSITIONS[@]}"; do
    internal_flag=${__BSD_META_POSITIONS_INTERNAL[$index]}
    if __bsd_metadata_visible "$include_internal" "$internal_flag"; then
      has_visible_positions=1
      break
    fi
  done

  if ((has_visible_positions)); then
    printf '\nArguments:\n'
    for index in "${!__BSD_META_POSITIONS[@]}"; do
      internal_flag=${__BSD_META_POSITIONS_INTERNAL[$index]}
      __bsd_metadata_visible "$include_internal" "$internal_flag" || continue
      record=${__BSD_META_POSITIONS[$index]}
      __bsd_split_record "$record"
      printf '  %-24s %s\n' "<$__BSD_RECORD_KEY>" "$__BSD_RECORD_VALUE"
    done
  fi

  for index in "${!__BSD_META_EXAMPLES[@]}"; do
    internal_flag=${__BSD_META_EXAMPLES_INTERNAL[$index]}
    if __bsd_metadata_visible "$include_internal" "$internal_flag"; then
      has_visible_examples=1
      break
    fi
  done

  if ((has_visible_examples)); then
    printf '\nExamples:\n'
    for index in "${!__BSD_META_EXAMPLES[@]}"; do
      internal_flag=${__BSD_META_EXAMPLES_INTERNAL[$index]}
      __bsd_metadata_visible "$include_internal" "$internal_flag" || continue
      summary=${__BSD_META_EXAMPLES[$index]}
      printf '  %s %s\n' "$script_name" "$summary"
    done
  fi
}

function __bsd_print_script_help {
  local script_name=${1:-${0##*/}}
  local include_internal=${2:-false}
  local function_name summary
  local -a commands=()

  __bsd_collect_public_commands commands || return $?

  printf 'Usage: %s <command> [args...]\n' "$script_name"
  printf '\nGlobal options:\n'
  printf '  %-24s %s\n' '-h, --help' 'Show script help'
  printf '  %-24s %s\n' '-v, --verbose' 'Enable verbose logging (debug level)'
  printf '  %-24s %s\n' '--completions [bash]' 'Print Bash completion script'
  printf '  %-24s %s\n' '--version' "Print ${__BSD_LIBRARY_NAME} version"
  printf '\nCommands:\n'

  if ((${#commands[@]} == 0)); then
    :
  else
    for function_name in "${commands[@]}"; do
      __bsd_load_metadata "$function_name" >/dev/null 2>&1 || continue
      __bsd_metadata_visible "$include_internal" "$__BSD_META_DOC_INTERNAL" || continue
      summary=${__BSD_META_DOC%%$'\n'*}
      printf '  %-20s %s\n' "$function_name" "$summary"
    done
  fi

  printf '\nRun '\''%s <command> --help'\'' for command details.\n' "$script_name"
}

function __bsd_usage_error {
  local function_name=$1
  local message=$2

  __BSD_LAST_EVENT=error
  log_error "$message"
  printf '\n' >&2
  __bsd_print_command_help "$function_name" >&2
  return 64
}

function @doc {
  local caller=${FUNCNAME[1]-}
  local status

  if [[ $# -eq 1 && (-z $caller || $caller == main || $caller == @main) ]]; then
    if __bsd_is_public_command "$1"; then
      __bsd_print_command_help "$1"
    else
      status=$?
      if ((status > 1)); then
        return "$status"
      fi
    fi
  fi

  return 0
}

function @arg {
  return 0
}

function @flag {
  return 0
}

function @position {
  return 0
}

function @example {
  return 0
}

function @internal {
  return 0
}

function @args {
  local function_name=${FUNCNAME[1]-}
  local token option_name value record include_internal='false' help_requested='false' status
  local preflight_token
  local position_index=0
  local -a position_values=()
  local -A seen_values=()

  __BSD_LAST_EVENT=''

  if [[ -z $function_name ]]; then
    log_error 'Unable to load command metadata for argument parsing'
    __BSD_LAST_EVENT=error
    return 64
  fi

  if __bsd_load_metadata "$function_name"; then
    :
  else
    status=$?
    if ((status > 1)); then
      __BSD_LAST_EVENT=error
      return "$status"
    fi

    log_error 'Unable to load command metadata for argument parsing'
    __BSD_LAST_EVENT=error
    return 64
  fi

  for record in "${__BSD_META_ARGS[@]}"; do
    __bsd_parse_arg_record "$record"
    __bsd_parse_option_signature "$__BSD_ARG_SIGNATURE" || continue
    if [[ $__BSD_ARG_HAS_DEFAULT == true ]]; then
      __bsd_assign_variable "$__BSD_SIG_NAME" "$__BSD_ARG_DEFAULT"
    else
      __bsd_assign_variable "$__BSD_SIG_NAME" ''
    fi
  done

  for record in "${__BSD_META_FLAGS[@]}"; do
    __bsd_split_record "$record"
    __bsd_parse_option_signature "$__BSD_RECORD_KEY" || continue
    __bsd_assign_variable "$__BSD_SIG_NAME" 'false'
  done

  for record in "${__BSD_META_POSITIONS[@]}"; do
    __bsd_split_record "$record"
    __bsd_assign_variable "$__BSD_RECORD_KEY" ''
  done

  for preflight_token in "$@"; do
    case "$preflight_token" in
    -h | --help)
      help_requested='true'
      ;;
    --internal)
      include_internal='true'
      ;;
    -v | --verbose)
      export LOG_LEVEL=debug
      ;;
    esac
  done

  if [[ $help_requested == true ]]; then
    __BSD_LAST_EVENT=help
    __bsd_print_command_help "$function_name" "${0##*/}" "$include_internal"
    return 1
  fi

  while (($# > 0)); do
    token=$1
    shift

    case "$token" in
    -h | --help)
      ;;
    --internal)
      ;;
    -v | --verbose)
      ;;
    --)
      while (($# > 0)); do
        position_values+=("$1")
        shift
      done
      break
      ;;
    --*=*)
      option_name=${token%%=*}
      value=${token#*=}

      if __bsd_find_option_record "$option_name" '__BSD_META_ARGS'; then
        __bsd_parse_option_signature "$__BSD_RECORD_KEY" || continue
        __bsd_assign_variable "$__BSD_SIG_NAME" "$value"
        seen_values["$__BSD_SIG_NAME"]=1
        continue
      fi

      if __bsd_find_option_record "$option_name" '__BSD_META_FLAGS'; then
        __bsd_parse_option_signature "$__BSD_RECORD_KEY" || continue
        __bsd_assign_variable "$__BSD_SIG_NAME" 'true'
        seen_values["$__BSD_SIG_NAME"]=1
        continue
      fi

      __bsd_usage_error "$function_name" "Unknown option: $option_name"
      return $?
      ;;
    --* | -?)
      if __bsd_find_option_record "$token" '__BSD_META_FLAGS'; then
        __bsd_parse_option_signature "$__BSD_RECORD_KEY" || continue
        __bsd_assign_variable "$__BSD_SIG_NAME" 'true'
        seen_values["$__BSD_SIG_NAME"]=1
        continue
      fi

      if __bsd_find_option_record "$token" '__BSD_META_ARGS'; then
        if (($# == 0)); then
          __bsd_usage_error "$function_name" "Missing value for option: $token"
          return $?
        fi

        value=$1
        shift
        __bsd_parse_option_signature "$__BSD_RECORD_KEY" || continue
        __bsd_assign_variable "$__BSD_SIG_NAME" "$value"
        seen_values["$__BSD_SIG_NAME"]=1
        continue
      fi

      __bsd_usage_error "$function_name" "Unknown option: $token"
      return $?
      ;;
    -*)
      __bsd_usage_error "$function_name" "Unknown option: $token"
      return $?
      ;;
    *)
      position_values+=("$token")
      ;;
    esac
  done

  for record in "${__BSD_META_ARGS[@]}"; do
    __bsd_parse_arg_record "$record"
    __bsd_parse_option_signature "$__BSD_ARG_SIGNATURE" || continue

    if [[ $__BSD_ARG_REQUIRED != true ]]; then
      continue
    fi

    if [[ -z ${seen_values[$__BSD_SIG_NAME]-} ]]; then
      __bsd_usage_error "$function_name" "Missing required option: $(if [[ -n $__BSD_SIG_LONG ]]; then printf '%s' "$__BSD_SIG_LONG"; else printf '%s' "$__BSD_SIG_SHORT"; fi)"
      return $?
    fi

    value=${!__BSD_SIG_NAME}
    if __bsd_is_blank_value "$value"; then
      __bsd_usage_error "$function_name" "Required option cannot be empty: $(if [[ -n $__BSD_SIG_LONG ]]; then printf '%s' "$__BSD_SIG_LONG"; else printf '%s' "$__BSD_SIG_SHORT"; fi)"
      return $?
    fi
  done

  for record in "${__BSD_META_POSITIONS[@]}"; do
    __bsd_split_record "$record"

    if ((position_index < ${#position_values[@]})); then
      value=${position_values[$position_index]}
      ((position_index += 1))

      if [[ -z ${seen_values[$__BSD_RECORD_KEY]-} ]]; then
        __bsd_assign_variable "$__BSD_RECORD_KEY" "$value"
        seen_values["$__BSD_RECORD_KEY"]=1
      fi
      continue
    fi

    if [[ -n ${seen_values[$__BSD_RECORD_KEY]-} ]]; then
      continue
    fi

    __bsd_usage_error "$function_name" "Missing positional argument: <$__BSD_RECORD_KEY>"
    return $?
  done

  if ((position_index < ${#position_values[@]})); then
    __bsd_usage_error "$function_name" "Unexpected positional argument: ${position_values[$position_index]}"
    return $?
  fi

  return 0
}

function @main {
  local script_name script_source command_name status shell_name include_internal='false' help_requested='false'

  script_name=${0##*/}
  script_source=${BASH_SOURCE[1]-$0}

  if (($# == 0)); then
    __bsd_print_script_help "$script_name"
    return 0
  fi

  while (($# > 0)); do
    case "$1" in
    -h | --help)
      help_requested='true'
      shift
      ;;
    --internal)
      include_internal='true'
      shift
      ;;
    -v | --verbose)
      export LOG_LEVEL=debug
      shift
      ;;
    --version)
      if (($# > 1)); then
        log_error 'Usage: %s [--version]' "$script_name"
        return 64
      fi
      __bsd_print_version
      return 0
      ;;
    --completions)
      shell_name=${2:-bash}
      if (($# > 2)); then
        log_error 'Usage: --completions [bash]'
        return 64
      fi

      case "$shell_name" in
      bash)
        __bsd_print_bash_completions "$script_name" "$script_source" "$0"
        return 0
        ;;
      *)
        log_error "Unsupported completion shell: $shell_name"
        return 64
        ;;
      esac
      ;;
    __complete)
      shift
      __bsd_complete "$@"
      return $?
      ;;
    *)
      break
      ;;
    esac
  done

  if [[ $help_requested == true ]]; then
    __bsd_print_script_help "$script_name" "$include_internal"
    return 0
  fi

  if (($# == 0)); then
    __bsd_print_script_help "$script_name"
    return 0
  fi

  command_name=$1
  shift

  if __bsd_is_public_command "$command_name"; then
    :
  else
    status=$?
    if ((status > 1)); then
      return "$status"
    fi

    log_error "Unknown command: $command_name"
    printf '\n' >&2
    __bsd_print_script_help "$script_name" >&2
    return 64
  fi

  __BSD_LAST_EVENT=''
  if "$command_name" "$@"; then
    if [[ ${__BSD_LAST_EVENT-} == error ]]; then
      return 64
    fi
    return 0
  else
    status=$?
  fi
  if [[ $status -eq 1 && ${__BSD_LAST_EVENT-} == help ]]; then
    return 0
  fi

  return "$status"
}

function __bsd_snapshot_base_functions {
  local function_name

  __BSD_BASE_FUNCTIONS=()
  while read -r _ _ function_name; do
    __BSD_BASE_FUNCTIONS["$function_name"]=1
  done < <(declare -F)
}

__bsd_snapshot_base_functions
