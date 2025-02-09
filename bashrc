#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '
. "$HOME/.cargo/env"

export PATH=$PATH:/snap/bin

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

#if command -v pyenv 1>/dev/null 2>&1; then
 #eval "$(pyenv init -)"
#fi
. "$HOME/.cargo/env"
#export PATH=${PATH}:`go env GOPATH`/bin
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export FONTCONFIG_PATH=/etc/fonts
export PASSWORD_STORE_DIR=~/.password-store
export BROWSER=/usr/bin/floorp
export EDITOR=vim

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/dan/Downloads/google-cloud-sdk/path.bash.inc' ]; then . '/home/dan/Downloads/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/dan/Downloads/google-cloud-sdk/completion.bash.inc' ]; then . '/home/dan/Downloads/google-cloud-sdk/completion.bash.inc'; fi

if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
export EDITOR=vim
export SDL_GAMECONTROLLERCONFIG="030072264c050000e60c000000016800,PS5 Controller new mapping,a:b0,b:b1,x:b2,y:b3,back:b4,guide:b15,start:b6,leftshoulder:b9,rightshoulder:b10,leftstick:b7,rightstick:b8,dpup:b11,dpleft:b13,dpdown:b12,dpright:b14,leftx:a0,lefty:a1,rightx:a2,righty:a3,lefttrigger:a4,righttrigger:a5,platform:Linux,"
export VAGRANT_DISABLE_STRICT_DEPENDENCY_ENFORCEMENT=1
export LESS=-R

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if [ -f ~/.bash_api_keys ]; then
    . ~/.bash_api_keys
fi

. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash
activate() {
    local search_dir="${1:-.}"  # Use $1 if provided, otherwise use current directory
    source $(find "$search_dir" -iname "activate")
}

eval "$(rbenv init -)"

# Shell-GPT integration BASH v0.2
_sgpt_bash() {
if [[ -n "$READLINE_LINE" ]]; then
    READLINE_LINE=$(sgpt --shell <<< "$READLINE_LINE" --no-interaction)
    READLINE_POINT=${#READLINE_LINE}
fi
}
bind -x '"\C-l": _sgpt_bash'

function brightness {
   xrandr --output DP-1 --brightness $1 && xrandr --output DP-2 --brightness $1
}



# if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
#     if tmux has-session -t template 2>/dev/null; then
#         # Clone the template session into a new session named after a pattern or use a unique identifier
#         NEW_SESSION=$(tmux new-session -d -t template -P)
#         tmux attach-session -t "$NEW_SESSION"
#     else
#         # Create a template session to clone from
#         tmux new-session -s template -d
#         # Add windows and commands to the template as needed
# 	#tmux new-window -t template -n 'Window1' 'top'
#         #tmux new-window -t template -n 'Window2' 'htop'
#         # Return to the first window if needed
#         tmux select-window -t template:0
#         # Attach to the template session
#         tmux attach-session -t template
#     fi
# fi

# if [ -z "$TMUX" ]; then
#   # Create a new session with a random UUID as the name
#   session_name=$(uuidgen | cut -c1-8)
#   tmux new-session -s "$session_name" -d && tmux attach-session -t "$session_name"
# fi
