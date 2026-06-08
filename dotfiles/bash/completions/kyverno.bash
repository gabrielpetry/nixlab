# bash completion for kyverno                              -*- shell-script -*-

__kyverno_debug()
{
    if [[ -n ${BASH_COMP_DEBUG_FILE:-} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}"
    fi
}

# Homebrew on Macs have version 1.3 of bash-completion which doesn't include
# _init_completion. This is a very minimal version of that function.
__kyverno_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

__kyverno_index_of_word()
{
    local w word=$1
    shift
    index=0
    for w in "$@"; do
        [[ $w = "$word" ]] && return
        index=$((index+1))
    done
    index=-1
}

__kyverno_contains_word()
{
    local w word=$1; shift
    for w in "$@"; do
        [[ $w = "$word" ]] && return
    done
    return 1
}

__kyverno_handle_go_custom_completion()
{
    __kyverno_debug "${FUNCNAME[0]}: cur is ${cur}, words[*] is ${words[*]}, #words[@] is ${#words[@]}"

    local shellCompDirectiveError=1
    local shellCompDirectiveNoSpace=2
    local shellCompDirectiveNoFileComp=4
    local shellCompDirectiveFilterFileExt=8
    local shellCompDirectiveFilterDirs=16

    local out requestComp lastParam lastChar comp directive args

    # Prepare the command to request completions for the program.
    # Calling ${words[0]} instead of directly kyverno allows handling aliases
    args=("${words[@]:1}")
    # Disable ActiveHelp which is not supported for bash completion v1
    requestComp="KYVERNO_ACTIVE_HELP=0 ${words[0]} __completeNoDesc ${args[*]}"

    lastParam=${words[$((${#words[@]}-1))]}
    lastChar=${lastParam:$((${#lastParam}-1)):1}
    __kyverno_debug "${FUNCNAME[0]}: lastParam ${lastParam}, lastChar ${lastChar}"

    if [ -z "${cur}" ] && [ "${lastChar}" != "=" ]; then
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go method.
        __kyverno_debug "${FUNCNAME[0]}: Adding extra empty parameter"
        requestComp="${requestComp} \"\""
    fi

    __kyverno_debug "${FUNCNAME[0]}: calling ${requestComp}"
    # Use eval to handle any environment variables and such
    out=$(eval "${requestComp}" 2>/dev/null)

    # Extract the directive integer at the very end of the output following a colon (:)
    directive=${out##*:}
    # Remove the directive
    out=${out%:*}
    if [ "${directive}" = "${out}" ]; then
        # There is not directive specified
        directive=0
    fi
    __kyverno_debug "${FUNCNAME[0]}: the completion directive is: ${directive}"
    __kyverno_debug "${FUNCNAME[0]}: the completions are: ${out}"

    if [ $((directive & shellCompDirectiveError)) -ne 0 ]; then
        # Error code.  No completion.
        __kyverno_debug "${FUNCNAME[0]}: received error from custom completion go code"
        return
    else
        if [ $((directive & shellCompDirectiveNoSpace)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __kyverno_debug "${FUNCNAME[0]}: activating no space"
                compopt -o nospace
            fi
        fi
        if [ $((directive & shellCompDirectiveNoFileComp)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __kyverno_debug "${FUNCNAME[0]}: activating no file completion"
                compopt +o default
            fi
        fi
    fi

    if [ $((directive & shellCompDirectiveFilterFileExt)) -ne 0 ]; then
        # File extension filtering
        local fullFilter filter filteringCmd
        # Do not use quotes around the $out variable or else newline
        # characters will be kept.
        for filter in ${out}; do
            fullFilter+="$filter|"
        done

        filteringCmd="_filedir $fullFilter"
        __kyverno_debug "File filtering command: $filteringCmd"
        $filteringCmd
    elif [ $((directive & shellCompDirectiveFilterDirs)) -ne 0 ]; then
        # File completion for directories only
        local subdir
        # Use printf to strip any trailing newline
        subdir=$(printf "%s" "${out}")
        if [ -n "$subdir" ]; then
            __kyverno_debug "Listing directories in $subdir"
            __kyverno_handle_subdirs_in_dir_flag "$subdir"
        else
            __kyverno_debug "Listing directories in ."
            _filedir -d
        fi
    else
        while IFS='' read -r comp; do
            COMPREPLY+=("$comp")
        done < <(compgen -W "${out}" -- "$cur")
    fi
}

__kyverno_handle_reply()
{
    __kyverno_debug "${FUNCNAME[0]}"
    local comp
    case $cur in
        -*)
            if [[ $(type -t compopt) = "builtin" ]]; then
                compopt -o nospace
            fi
            local allflags
            if [ ${#must_have_one_flag[@]} -ne 0 ]; then
                allflags=("${must_have_one_flag[@]}")
            else
                allflags=("${flags[*]} ${two_word_flags[*]}")
            fi
            while IFS='' read -r comp; do
                COMPREPLY+=("$comp")
            done < <(compgen -W "${allflags[*]}" -- "$cur")
            if [[ $(type -t compopt) = "builtin" ]]; then
                [[ "${COMPREPLY[0]}" == *= ]] || compopt +o nospace
            fi

            # complete after --flag=abc
            if [[ $cur == *=* ]]; then
                if [[ $(type -t compopt) = "builtin" ]]; then
                    compopt +o nospace
                fi

                local index flag
                flag="${cur%=*}"
                __kyverno_index_of_word "${flag}" "${flags_with_completion[@]}"
                COMPREPLY=()
                if [[ ${index} -ge 0 ]]; then
                    PREFIX=""
                    cur="${cur#*=}"
                    ${flags_completion[${index}]}
                    if [ -n "${ZSH_VERSION:-}" ]; then
                        # zsh completion needs --flag= prefix
                        eval "COMPREPLY=( \"\${COMPREPLY[@]/#/${flag}=}\" )"
                    fi
                fi
            fi

            if [[ -z "${flag_parsing_disabled}" ]]; then
                # If flag parsing is enabled, we have completed the flags and can return.
                # If flag parsing is disabled, we may not know all (or any) of the flags, so we fallthrough
                # to possibly call handle_go_custom_completion.
                return 0;
            fi
            ;;
    esac

    # check if we are handling a flag with special work handling
    local index
    __kyverno_index_of_word "${prev}" "${flags_with_completion[@]}"
    if [[ ${index} -ge 0 ]]; then
        ${flags_completion[${index}]}
        return
    fi

    # we are parsing a flag and don't have a special handler, no completion
    if [[ ${cur} != "${words[cword]}" ]]; then
        return
    fi

    local completions
    completions=("${commands[@]}")
    if [[ ${#must_have_one_noun[@]} -ne 0 ]]; then
        completions+=("${must_have_one_noun[@]}")
    elif [[ -n "${has_completion_function}" ]]; then
        # if a go completion function is provided, defer to that function
        __kyverno_handle_go_custom_completion
    fi
    if [[ ${#must_have_one_flag[@]} -ne 0 ]]; then
        completions+=("${must_have_one_flag[@]}")
    fi
    while IFS='' read -r comp; do
        COMPREPLY+=("$comp")
    done < <(compgen -W "${completions[*]}" -- "$cur")

    if [[ ${#COMPREPLY[@]} -eq 0 && ${#noun_aliases[@]} -gt 0 && ${#must_have_one_noun[@]} -ne 0 ]]; then
        while IFS='' read -r comp; do
            COMPREPLY+=("$comp")
        done < <(compgen -W "${noun_aliases[*]}" -- "$cur")
    fi

    if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
        if declare -F __kyverno_custom_func >/dev/null; then
            # try command name qualified custom func
            __kyverno_custom_func
        else
            # otherwise fall back to unqualified for compatibility
            declare -F __custom_func >/dev/null && __custom_func
        fi
    fi

    # available in bash-completion >= 2, not always present on macOS
    if declare -F __ltrim_colon_completions >/dev/null; then
        __ltrim_colon_completions "$cur"
    fi

    # If there is only 1 completion and it is a flag with an = it will be completed
    # but we don't want a space after the =
    if [[ "${#COMPREPLY[@]}" -eq "1" ]] && [[ $(type -t compopt) = "builtin" ]] && [[ "${COMPREPLY[0]}" == --*= ]]; then
       compopt -o nospace
    fi
}

# The arguments should be in the form "ext1|ext2|extn"
__kyverno_handle_filename_extension_flag()
{
    local ext="$1"
    _filedir "@(${ext})"
}

__kyverno_handle_subdirs_in_dir_flag()
{
    local dir="$1"
    pushd "${dir}" >/dev/null 2>&1 && _filedir -d && popd >/dev/null 2>&1 || return
}

__kyverno_handle_flag()
{
    __kyverno_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    # if a command required a flag, and we found it, unset must_have_one_flag()
    local flagname=${words[c]}
    local flagvalue=""
    # if the word contained an =
    if [[ ${words[c]} == *"="* ]]; then
        flagvalue=${flagname#*=} # take in as flagvalue after the =
        flagname=${flagname%=*} # strip everything after the =
        flagname="${flagname}=" # but put the = back
    fi
    __kyverno_debug "${FUNCNAME[0]}: looking for ${flagname}"
    if __kyverno_contains_word "${flagname}" "${must_have_one_flag[@]}"; then
        must_have_one_flag=()
    fi

    # if you set a flag which only applies to this command, don't show subcommands
    if __kyverno_contains_word "${flagname}" "${local_nonpersistent_flags[@]}"; then
      commands=()
    fi

    # keep flag value with flagname as flaghash
    # flaghash variable is an associative array which is only supported in bash > 3.
    if [[ -z "${BASH_VERSION:-}" || "${BASH_VERSINFO[0]:-}" -gt 3 ]]; then
        if [ -n "${flagvalue}" ] ; then
            flaghash[${flagname}]=${flagvalue}
        elif [ -n "${words[ $((c+1)) ]}" ] ; then
            flaghash[${flagname}]=${words[ $((c+1)) ]}
        else
            flaghash[${flagname}]="true" # pad "true" for bool flag
        fi
    fi

    # skip the argument to a two word flag
    if [[ ${words[c]} != *"="* ]] && __kyverno_contains_word "${words[c]}" "${two_word_flags[@]}"; then
        __kyverno_debug "${FUNCNAME[0]}: found a flag ${words[c]}, skip the next argument"
        c=$((c+1))
        # if we are looking for a flags value, don't show commands
        if [[ $c -eq $cword ]]; then
            commands=()
        fi
    fi

    c=$((c+1))

}

__kyverno_handle_noun()
{
    __kyverno_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    if __kyverno_contains_word "${words[c]}" "${must_have_one_noun[@]}"; then
        must_have_one_noun=()
    elif __kyverno_contains_word "${words[c]}" "${noun_aliases[@]}"; then
        must_have_one_noun=()
    fi

    nouns+=("${words[c]}")
    c=$((c+1))
}

__kyverno_handle_command()
{
    __kyverno_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    local next_command
    if [[ -n ${last_command} ]]; then
        next_command="_${last_command}_${words[c]//:/__}"
    else
        if [[ $c -eq 0 ]]; then
            next_command="_kyverno_root_command"
        else
            next_command="_${words[c]//:/__}"
        fi
    fi
    c=$((c+1))
    __kyverno_debug "${FUNCNAME[0]}: looking for ${next_command}"
    declare -F "$next_command" >/dev/null && $next_command
}

__kyverno_handle_word()
{
    if [[ $c -ge $cword ]]; then
        __kyverno_handle_reply
        return
    fi
    __kyverno_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"
    if [[ "${words[c]}" == -* ]]; then
        __kyverno_handle_flag
    elif __kyverno_contains_word "${words[c]}" "${commands[@]}"; then
        __kyverno_handle_command
    elif [[ $c -eq 0 ]]; then
        __kyverno_handle_command
    elif __kyverno_contains_word "${words[c]}" "${command_aliases[@]}"; then
        # aliashash variable is an associative array which is only supported in bash > 3.
        if [[ -z "${BASH_VERSION:-}" || "${BASH_VERSINFO[0]:-}" -gt 3 ]]; then
            words[c]=${aliashash[${words[c]}]}
            __kyverno_handle_command
        else
            __kyverno_handle_noun
        fi
    else
        __kyverno_handle_noun
    fi
    __kyverno_handle_word
}

_kyverno_apply()
{
    last_command="kyverno_apply"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--audit-warn")
    local_nonpersistent_flags+=("--audit-warn")
    flags+=("--cluster")
    flags+=("-c")
    local_nonpersistent_flags+=("--cluster")
    local_nonpersistent_flags+=("-c")
    flags+=("--cluster-wide-resources")
    local_nonpersistent_flags+=("--cluster-wide-resources")
    flags+=("--context=")
    two_word_flags+=("--context")
    local_nonpersistent_flags+=("--context")
    local_nonpersistent_flags+=("--context=")
    flags+=("--context-file=")
    two_word_flags+=("--context-file")
    local_nonpersistent_flags+=("--context-file")
    local_nonpersistent_flags+=("--context-file=")
    flags+=("--continue-on-fail")
    local_nonpersistent_flags+=("--continue-on-fail")
    flags+=("--detailed-results")
    local_nonpersistent_flags+=("--detailed-results")
    flags+=("--exception=")
    two_word_flags+=("--exception")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--exception")
    local_nonpersistent_flags+=("--exception=")
    local_nonpersistent_flags+=("-e")
    flags+=("--exceptions=")
    two_word_flags+=("--exceptions")
    local_nonpersistent_flags+=("--exceptions")
    local_nonpersistent_flags+=("--exceptions=")
    flags+=("--exceptions-with-resources")
    local_nonpersistent_flags+=("--exceptions-with-resources")
    flags+=("--generate-exceptions")
    local_nonpersistent_flags+=("--generate-exceptions")
    flags+=("--generated-exception-ttl=")
    two_word_flags+=("--generated-exception-ttl")
    local_nonpersistent_flags+=("--generated-exception-ttl")
    local_nonpersistent_flags+=("--generated-exception-ttl=")
    flags+=("--git-branch=")
    two_word_flags+=("--git-branch")
    two_word_flags+=("-b")
    local_nonpersistent_flags+=("--git-branch")
    local_nonpersistent_flags+=("--git-branch=")
    local_nonpersistent_flags+=("-b")
    flags+=("--json=")
    two_word_flags+=("--json")
    local_nonpersistent_flags+=("--json")
    local_nonpersistent_flags+=("--json=")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    local_nonpersistent_flags+=("--kubeconfig")
    local_nonpersistent_flags+=("--kubeconfig=")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace")
    local_nonpersistent_flags+=("--namespace=")
    local_nonpersistent_flags+=("-n")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output")
    local_nonpersistent_flags+=("--output=")
    local_nonpersistent_flags+=("-o")
    flags+=("--output-format=")
    two_word_flags+=("--output-format")
    local_nonpersistent_flags+=("--output-format")
    local_nonpersistent_flags+=("--output-format=")
    flags+=("--parameter-resource=")
    two_word_flags+=("--parameter-resource")
    local_nonpersistent_flags+=("--parameter-resource")
    local_nonpersistent_flags+=("--parameter-resource=")
    flags+=("--password=")
    two_word_flags+=("--password")
    local_nonpersistent_flags+=("--password")
    local_nonpersistent_flags+=("--password=")
    flags+=("--policy-report")
    flags+=("-p")
    local_nonpersistent_flags+=("--policy-report")
    local_nonpersistent_flags+=("-p")
    flags+=("--registry")
    local_nonpersistent_flags+=("--registry")
    flags+=("--remove-color")
    local_nonpersistent_flags+=("--remove-color")
    flags+=("--resource=")
    two_word_flags+=("--resource")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--resource")
    local_nonpersistent_flags+=("--resource=")
    local_nonpersistent_flags+=("-r")
    flags+=("--resources=")
    two_word_flags+=("--resources")
    local_nonpersistent_flags+=("--resources")
    local_nonpersistent_flags+=("--resources=")
    flags+=("--set=")
    two_word_flags+=("--set")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--set")
    local_nonpersistent_flags+=("--set=")
    local_nonpersistent_flags+=("-s")
    flags+=("--stdin")
    flags+=("-i")
    local_nonpersistent_flags+=("--stdin")
    local_nonpersistent_flags+=("-i")
    flags+=("--table")
    flags+=("-t")
    local_nonpersistent_flags+=("--table")
    local_nonpersistent_flags+=("-t")
    flags+=("--target-resource=")
    two_word_flags+=("--target-resource")
    local_nonpersistent_flags+=("--target-resource")
    local_nonpersistent_flags+=("--target-resource=")
    flags+=("--target-resources=")
    two_word_flags+=("--target-resources")
    local_nonpersistent_flags+=("--target-resources")
    local_nonpersistent_flags+=("--target-resources=")
    flags+=("--userinfo=")
    two_word_flags+=("--userinfo")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--userinfo")
    local_nonpersistent_flags+=("--userinfo=")
    local_nonpersistent_flags+=("-u")
    flags+=("--username=")
    two_word_flags+=("--username")
    local_nonpersistent_flags+=("--username")
    local_nonpersistent_flags+=("--username=")
    flags+=("--values-file=")
    two_word_flags+=("--values-file")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--values-file")
    local_nonpersistent_flags+=("--values-file=")
    local_nonpersistent_flags+=("-f")
    flags+=("--warn-exit-code=")
    two_word_flags+=("--warn-exit-code")
    local_nonpersistent_flags+=("--warn-exit-code")
    local_nonpersistent_flags+=("--warn-exit-code=")
    flags+=("--warn-no-pass")
    local_nonpersistent_flags+=("--warn-no-pass")
    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kyverno_completion()
{
    last_command="kyverno_completion"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--help")
    flags+=("-h")
    local_nonpersistent_flags+=("--help")
    local_nonpersistent_flags+=("-h")
    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    must_have_one_noun+=("bash")
    must_have_one_noun+=("fish")
    must_have_one_noun+=("powershell")
    must_have_one_noun+=("zsh")
    noun_aliases=()
}

_kyverno_create_cluster-role()
{
    last_command="kyverno_create_cluster-role"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--api-groups=")
    two_word_flags+=("--api-groups")
    two_word_flags+=("-g")
    local_nonpersistent_flags+=("--api-groups")
    local_nonpersistent_flags+=("--api-groups=")
    local_nonpersistent_flags+=("-g")
    flags+=("--controllers=")
    two_word_flags+=("--controllers")
    local_nonpersistent_flags+=("--controllers")
    local_nonpersistent_flags+=("--controllers=")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output")
    local_nonpersistent_flags+=("--output=")
    local_nonpersistent_flags+=("-o")
    flags+=("--resources=")
    two_word_flags+=("--resources")
    local_nonpersistent_flags+=("--resources")
    local_nonpersistent_flags+=("--resources=")
    flags+=("--verbs=")
    two_word_flags+=("--verbs")
    local_nonpersistent_flags+=("--verbs")
    local_nonpersistent_flags+=("--verbs=")
    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_flag+=("--api-groups=")
    must_have_one_flag+=("-g")
    must_have_one_flag+=("--resources=")
    must_have_one_flag+=("--verbs=")
    must_have_one_noun=()
    noun_aliases=()
}

_kyverno_create_exception()
{
    last_command="kyverno_create_exception"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--all=")
    two_word_flags+=("--all")
    local_nonpersistent_flags+=("--all")
    local_nonpersistent_flags+=("--all=")
    flags+=("--any=")
    two_word_flags+=("--any")
    local_nonpersistent_flags+=("--any")
    local_nonpersistent_flags+=("--any=")
    flags+=("--background")
    flags+=("-b")
    local_nonpersistent_flags+=("--background")
    local_nonpersistent_flags+=("-b")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    local_nonpersistent_flags+=("--namespace")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output")
    local_nonpersistent_flags+=("--output=")
    local_nonpersistent_flags+=("-o")
    flags+=("--policy-rules=")
    two_word_flags+=("--policy-rules")
    local_nonpersistent_flags+=("--policy-rules")
    local_nonpersistent_flags+=("--policy-rules=")
    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_flag+=("--policy-rules=")
    must_have_one_noun=()
    noun_aliases=()
}

_kyverno_create_metrics-config()
{
    last_command="kyverno_create_metrics-config"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--exclude=")
    two_word_flags+=("--exclude")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--exclude")
    local_nonpersistent_flags+=("--exclude=")
    local_nonpersistent_flags+=("-e")
    flags+=("--include=")
    two_word_flags+=("--include")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--include")
    local_nonpersistent_flags+=("--include=")
    local_nonpersistent_flags+=("-i")
    flags+=("--name=")
    two_word_flags+=("--name")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name")
    local_nonpersistent_flags+=("--name=")
    local_nonpersistent_flags+=("-n")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    local_nonpersistent_flags+=("--namespace")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output")
    local_nonpersistent_flags+=("--output=")
    local_nonpersistent_flags+=("-o")
    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kyverno_create_test()
{
    last_command="kyverno_create_test"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--fail=")
    two_word_flags+=("--fail")
    local_nonpersistent_flags+=("--fail")
    local_nonpersistent_flags+=("--fail=")
    flags+=("--name=")
    two_word_flags+=("--name")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name")
    local_nonpersistent_flags+=("--name=")
    local_nonpersistent_flags+=("-n")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output")
    local_nonpersistent_flags+=("--output=")
    local_nonpersistent_flags+=("-o")
    flags+=("--pass=")
    two_word_flags+=("--pass")
    local_nonpersistent_flags+=("--pass")
    local_nonpersistent_flags+=("--pass=")
    flags+=("--policy=")
    two_word_flags+=("--policy")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--policy")
    local_nonpersistent_flags+=("--policy=")
    local_nonpersistent_flags+=("-p")
    flags+=("--resource=")
    two_word_flags+=("--resource")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--resource")
    local_nonpersistent_flags+=("--resource=")
    local_nonpersistent_flags+=("-r")
    flags+=("--skip=")
    two_word_flags+=("--skip")
    local_nonpersistent_flags+=("--skip")
    local_nonpersistent_flags+=("--skip=")
    flags+=("--values=")
    two_word_flags+=("--values")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--values")
    local_nonpersistent_flags+=("--values=")
    local_nonpersistent_flags+=("-f")
    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kyverno_create_user-info()
{
    last_command="kyverno_create_user-info"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--cluster-role=")
    two_word_flags+=("--cluster-role")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--cluster-role")
    local_nonpersistent_flags+=("--cluster-role=")
    local_nonpersistent_flags+=("-c")
    flags+=("--group=")
    two_word_flags+=("--group")
    two_word_flags+=("-g")
    local_nonpersistent_flags+=("--group")
    local_nonpersistent_flags+=("--group=")
    local_nonpersistent_flags+=("-g")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output")
    local_nonpersistent_flags+=("--output=")
    local_nonpersistent_flags+=("-o")
    flags+=("--role=")
    two_word_flags+=("--role")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--role")
    local_nonpersistent_flags+=("--role=")
    local_nonpersistent_flags+=("-r")
    flags+=("--username=")
    two_word_flags+=("--username")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--username")
    local_nonpersistent_flags+=("--username=")
    local_nonpersistent_flags+=("-u")
    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kyverno_create_values()
{
    last_command="kyverno_create_values"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--global=")
    two_word_flags+=("--global")
    two_word_flags+=("-g")
    local_nonpersistent_flags+=("--global")
    local_nonpersistent_flags+=("--global=")
    local_nonpersistent_flags+=("-g")
    flags+=("--ns-selector=")
    two_word_flags+=("--ns-selector")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--ns-selector")
    local_nonpersistent_flags+=("--ns-selector=")
    local_nonpersistent_flags+=("-n")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output")
    local_nonpersistent_flags+=("--output=")
    local_nonpersistent_flags+=("-o")
    flags+=("--resource=")
    two_word_flags+=("--resource")
    local_nonpersistent_flags+=("--resource")
    local_nonpersistent_flags+=("--resource=")
    flags+=("--rule=")
    two_word_flags+=("--rule")
    local_nonpersistent_flags+=("--rule")
    local_nonpersistent_flags+=("--rule=")
    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kyverno_create()
{
    last_command="kyverno_create"

    command_aliases=()

    commands=()
    commands+=("cluster-role")
    commands+=("exception")
    commands+=("metrics-config")
    commands+=("test")
    commands+=("user-info")
    commands+=("values")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kyverno_docs()
{
    last_command="kyverno_docs"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--autogenTag")
    local_nonpersistent_flags+=("--autogenTag")
    flags+=("--markdownLinks")
    local_nonpersistent_flags+=("--markdownLinks")
    flags+=("--noDate")
    local_nonpersistent_flags+=("--noDate")
    flags+=("--output=")
    two_word_flags+=("--output")
    flags_with_completion+=("--output")
    flags_completion+=("_filedir -d")
    two_word_flags+=("-o")
    flags_with_completion+=("-o")
    flags_completion+=("_filedir -d")
    local_nonpersistent_flags+=("--output")
    local_nonpersistent_flags+=("--output=")
    local_nonpersistent_flags+=("-o")
    flags+=("--website")
    local_nonpersistent_flags+=("--website")
    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_flag+=("--output=")
    must_have_one_flag+=("-o")
    must_have_one_noun=()
    noun_aliases=()
}

_kyverno_help()
{
    last_command="kyverno_help"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_kyverno_jp_function()
{
    last_command="kyverno_jp_function"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kyverno_jp_parse()
{
    last_command="kyverno_jp_parse"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--file=")
    two_word_flags+=("--file")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--file")
    local_nonpersistent_flags+=("--file=")
    local_nonpersistent_flags+=("-f")
    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kyverno_jp_query()
{
    last_command="kyverno_jp_query"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--compact")
    flags+=("-c")
    local_nonpersistent_flags+=("--compact")
    local_nonpersistent_flags+=("-c")
    flags+=("--input=")
    two_word_flags+=("--input")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--input")
    local_nonpersistent_flags+=("--input=")
    local_nonpersistent_flags+=("-i")
    flags+=("--query=")
    two_word_flags+=("--query")
    two_word_flags+=("-q")
    local_nonpersistent_flags+=("--query")
    local_nonpersistent_flags+=("--query=")
    local_nonpersistent_flags+=("-q")
    flags+=("--unquoted")
    flags+=("-u")
    local_nonpersistent_flags+=("--unquoted")
    local_nonpersistent_flags+=("-u")
    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kyverno_jp()
{
    last_command="kyverno_jp"

    command_aliases=()

    commands=()
    commands+=("function")
    commands+=("parse")
    commands+=("query")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kyverno_json_scan()
{
    last_command="kyverno_json_scan"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--labels=")
    two_word_flags+=("--labels")
    local_nonpersistent_flags+=("--labels")
    local_nonpersistent_flags+=("--labels=")
    flags+=("--output=")
    two_word_flags+=("--output")
    local_nonpersistent_flags+=("--output")
    local_nonpersistent_flags+=("--output=")
    flags+=("--payload=")
    two_word_flags+=("--payload")
    local_nonpersistent_flags+=("--payload")
    local_nonpersistent_flags+=("--payload=")
    flags+=("--policy=")
    two_word_flags+=("--policy")
    local_nonpersistent_flags+=("--policy")
    local_nonpersistent_flags+=("--policy=")
    flags+=("--pre-process=")
    two_word_flags+=("--pre-process")
    local_nonpersistent_flags+=("--pre-process")
    local_nonpersistent_flags+=("--pre-process=")
    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kyverno_json()
{
    last_command="kyverno_json"

    command_aliases=()

    commands=()
    commands+=("scan")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kyverno_migrate()
{
    last_command="kyverno_migrate"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    local_nonpersistent_flags+=("--context")
    local_nonpersistent_flags+=("--context=")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    local_nonpersistent_flags+=("--kubeconfig")
    local_nonpersistent_flags+=("--kubeconfig=")
    flags+=("--resource=")
    two_word_flags+=("--resource")
    local_nonpersistent_flags+=("--resource")
    local_nonpersistent_flags+=("--resource=")
    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kyverno_test()
{
    last_command="kyverno_test"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--detailed-results")
    local_nonpersistent_flags+=("--detailed-results")
    flags+=("--fail-only")
    local_nonpersistent_flags+=("--fail-only")
    flags+=("--file-name=")
    two_word_flags+=("--file-name")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--file-name")
    local_nonpersistent_flags+=("--file-name=")
    local_nonpersistent_flags+=("-f")
    flags+=("--git-branch=")
    two_word_flags+=("--git-branch")
    two_word_flags+=("-b")
    local_nonpersistent_flags+=("--git-branch")
    local_nonpersistent_flags+=("--git-branch=")
    local_nonpersistent_flags+=("-b")
    flags+=("--output-format=")
    two_word_flags+=("--output-format")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output-format")
    local_nonpersistent_flags+=("--output-format=")
    local_nonpersistent_flags+=("-o")
    flags+=("--registry")
    local_nonpersistent_flags+=("--registry")
    flags+=("--remove-color")
    local_nonpersistent_flags+=("--remove-color")
    flags+=("--require-tests")
    local_nonpersistent_flags+=("--require-tests")
    flags+=("--test-case-selector=")
    two_word_flags+=("--test-case-selector")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--test-case-selector")
    local_nonpersistent_flags+=("--test-case-selector=")
    local_nonpersistent_flags+=("-t")
    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kyverno_version()
{
    last_command="kyverno_version"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_kyverno_root_command()
{
    last_command="kyverno"

    command_aliases=()

    commands=()
    commands+=("apply")
    commands+=("completion")
    commands+=("create")
    commands+=("docs")
    commands+=("help")
    commands+=("jp")
    commands+=("json")
    commands+=("migrate")
    commands+=("test")
    commands+=("version")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--add_dir_header")
    flags+=("--alsologtostderr")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    flags+=("--log_backtrace_at=")
    two_word_flags+=("--log_backtrace_at")
    flags+=("--log_dir=")
    two_word_flags+=("--log_dir")
    flags+=("--log_file=")
    two_word_flags+=("--log_file")
    flags+=("--log_file_max_size=")
    two_word_flags+=("--log_file_max_size")
    flags+=("--logtostderr")
    flags+=("--one_output")
    flags+=("--skip_headers")
    flags+=("--skip_log_headers")
    flags+=("--stderrthreshold=")
    two_word_flags+=("--stderrthreshold")
    flags+=("--v=")
    two_word_flags+=("--v")
    two_word_flags+=("-v")
    flags+=("--vmodule=")
    two_word_flags+=("--vmodule")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

__start_kyverno()
{
    local cur prev words cword split
    declare -A flaghash 2>/dev/null || :
    declare -A aliashash 2>/dev/null || :
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -s || return
    else
        __kyverno_init_completion -n "=" || return
    fi

    local c=0
    local flag_parsing_disabled=
    local flags=()
    local two_word_flags=()
    local local_nonpersistent_flags=()
    local flags_with_completion=()
    local flags_completion=()
    local commands=("kyverno")
    local command_aliases=()
    local must_have_one_flag=()
    local must_have_one_noun=()
    local has_completion_function=""
    local last_command=""
    local nouns=()
    local noun_aliases=()

    __kyverno_handle_word
}

if [[ $(type -t compopt) = "builtin" ]]; then
    complete -o default -F __start_kyverno kyverno
else
    complete -o default -o nospace -F __start_kyverno kyverno
fi

# ex: ts=4 sw=4 et filetype=sh
