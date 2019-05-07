# Initialize

! which tmux >/dev/null 2>&1 || [[ -n $TMUX ]] \
    || tmux attach -d || tmux -2 new

[[ ! -f /etc/bashrc ]] || . /etc/bashrc


# Functions

mkcd() { install -Ddm755 "$1" && cd "$1"; }
mkfile() { install -Dm644 /dev/null "$1"; }

printfetch() { printf '\e[32m%-10s\e[m \e[37m%-20s\e[m\n' "$1" "$2"; }

fetch() {
    local distro=$(awk -F= '/^NAME=/{gsub(/"/, "", $2); print $2}' /etc/os-release)
    printfetch 'user'   "$USER@$HOSTNAME"
    printfetch 'distro' "$distro"
    printfetch 'shell'   "${SHELL##*/}"
}

slack-notify_usage() {
    cat <<EOF >&2
Usage slack-notify [OPTIONS] "PRETEXT" ["TITLE" ["TEXT"]]

Options:
  -c CHANNEL        post channel name.
  -n NAME           disp username.
  -u URGENT         low, normal and critical.

EOF
}

slack-notify() {
    [[ -n $SLACK_WEBHOOK_URI ]] || {
        cat <<EOF >&2
echo "export SLACK_WEBHOOK_URI='WEBHOOK_URI'" > ~/.bashrc.local
EOF
        return 1
    }

    local args=$(getopt c:n:u: -- "$@")
    eval set -- "$args"

    local channel=general \
          name=slack-notify \
          urgent=normal

    while [[ $# -gt 0 ]]; do
        case $1 in
            --) shift; break ;;
            -c) shift; channel="$1" ;;
            -n) shift; name="$1" ;;
            -u) shift; urgent="$1" ;;
        esac
        shift
    done

    [[ -n $1 ]] || {
        slack-notify_usage
        return 2
    }

    case $urgent in
        low) color=#535c68 ;;
        normal) color=#6ab04c ;;
        critical) color=#eb4d4b ;;
        *) slack-notify_usage; return 3 ;;
    esac

    pretext="$1"
    title="$2"
    text=$(echo "$3" | awk -v 'ORS=\\n' '{gsub(/"/, "\\\""); print}')

    local data=$(mktemp /tmp/slack-notify-XXXXXXXX)
    cat <<EOF > $data
{
  "username": "$name",
  "channel": "$channel",
  "attachments": [
    {
      "pretext": "$pretext",
      "title": "$title",
      "text": "$text",
      "color": "$color"
    }
  ]
}
EOF

    result=$(curl -X POST -Ss -d "@$data" "$SLACK_WEBHOOK_URI")
    [[ $result = ok ]] || cat $data
    rm -f $data
}


# Completions

shopt -s dotglob \
      extglob \
      nullglob \
      nocaseglob \
      globstar


# History

shopt -s histappend


# Environment variables

export PATH=~/bin:$PATH

eval $(dircolors)


# Prompt


# Other

alias reload='exec $SHELL -l'

## diff
alias diff='command diff --color=auto'

## gpg
pidof gpg-agent >/dev/null 2>&1 \
    || LANG=C gpg-connect-agent /bye >/dev/null 2>&1

unset SSH_AGENT_PID
export SSH_AUTH_SOCK=$(LANG=C gpgconf --list-dirs agent-ssh-socket)

export GPG_TTY=$(tty)
LANG=C gpg-connect-agent updatestartuptty /bye >/dev/null

## grep
export GREP_COLOR='1;32'
alias grep='command grep --color=auto'

## less
export LESS='giRSW'

! which highlight >/dev/null 2>&1 \
    || LESSOPEN='| highlight -O xterm256 -s molokai --force -l -m 1 %s'

## ls
alias ls='command ls -v --time-style=+%FT%T --color=auto --group-directories-first'
alias la='ls -A'
alias ll='ls -l'
alias lla='ls -Al'


# Load local file

[[ ! -f ~/.bashrc.local ]] || . ~/.bashrc.local
