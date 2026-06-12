#!/usr/bin/env bash

abbrev-alias gitclean="git clean -fd; git reset --hard"
abbrev-alias gd="git diff"
abbrev-alias ga="git add"
abbrev-alias gsw="git switch"
abbrev-alias push="git push origin \$(git branch --show-current)"

abbrev-alias pull="git fetch --prune; git pull origin \$(git branch --show-current)"

abbrev-alias -g T=" 2>&1 | tail -n "
abbrev-alias -g H=" 2>&1 | head -n "
abbrev-alias -g J=" 2>&1 | jq -r "
abbrev-alias -g Y=" 2>&1 | yq -r "
abbrev-alias -g P=" 2>&1 | "
abbrev-alias -g W='| wc -l'
abbrev-alias -g WL='| wl-copy'
abbrev-alias -g 2null=' 2>/dev/null 3>&1'
abbrev-alias -g G=' 2>&1 | grep --color -i '
abbrev-alias -g Ga=' 2>&1 | grep --color=always -e "^" -i -e '
abbrev-alias -g C="| fcut"
abbrev-alias -g CC="| copy"
abbrev-alias -g S="| sort"
abbrev-alias -g U="| uniq"
abbrev-alias -g X="| xargs"
abbrev-alias -g XX="| xargs -I{}"
abbrev-alias -g XEVAL="|xargs -i -t sh -c \"{}\""
abbrev-alias -g A="| fawk"
abbrev-alias -g W="| wc -l"
abbrev-alias -g Y="| yq -r .data."
abbrev-alias -g XC="| wl-copy"
abbrev-alias -g B="| base64 -d"
abbrev-alias -g BC="| base64 -d | copy"
abbrev-alias -g kubesecret="| base64 -w 0| xclip -selection clipboard"
abbrev-alias k='kubectl'