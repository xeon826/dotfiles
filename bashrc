#
# ~/.bashrc
#

# set vi mode. Note: :cq to quit editor mode without executing command
# set -o vi

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
export BROWSER=/usr/bin/firefox
export PATH="$PATH:$HOME/.luarocks/bin"
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

activate() {
    local search_dir="${1:-.}"  # Use $1 if provided, otherwise use current directory
    source $(find "$search_dir" -iname "activate")
}

start() {
    local search_dir="${1:-.}"  # Use $1 if provided, otherwise use current directory
    local original_dir="$(pwd)"
    
    # Find the closest devbox.json file
    local devbox_dir="$(dirname "$(find "$search_dir" -name "devbox.json" | head -1)")"
    
    if [ -n "$devbox_dir" ]; then
        cd "$devbox_dir"
        source $(find . -iname "start" | head -1);
        cd "$original_dir"
    else
        source $(find "$search_dir" -iname "start" | head -1)
    fi
}

bind '"\C-g":"lazygit\n"'

bind '"\C-n":"nvim\n"'

bind '"\C-l":"claude\n"'

bind '"\C-b":"cd ..\n"'

bind '"\C-f":"ranger\n"'

function brightness {
   xrandr --output DP-1 --brightness $1 && xrandr --output DP-2 --brightness $1
}

export ANDROID_SDK_ROOT=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_SDK_ROOT/emulator
export PATH=$PATH:$ANDROID_SDK_ROOT/tools
export PATH=$PATH:$ANDROID_SDK_ROOT/tools/bin
export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools
export LIBVIRT_DEFAULT_URI="qemu:///system"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
export TERM=xterm-kitty

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --bash)"

export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
  --highlight-line \
  --info=inline-right \
  --ansi \
  --layout=reverse \
  --border=none \
  --color=bg+:#283457 \
  --color=bg:#16161e \
  --color=border:#27a1b9 \
  --color=fg:#c0caf5 \
  --color=gutter:#16161e \
  --color=header:#ff9e64 \
  --color=hl+:#2ac3de \
  --color=hl:#2ac3de \
  --color=info:#545c7e \
  --color=marker:#ff007c \
  --color=pointer:#ff007c \
  --color=prompt:#2ac3de \
  --color=query:#c0caf5:regular \
  --color=scrollbar:#27a1b9 \
  --color=separator:#ff9e64 \
  --color=spinner:#ff007c \
"
export SILLYTAVERN_LISTEN=true 
export SILLYTAVERN_PORT=8002
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export PATH="/home/dan/.config/herd-lite/bin:$PATH"
export PHP_INI_SCAN_DIR="/home/dan/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/dan/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/dan/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/dan/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/dan/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PATH="$PATH:$HOME/bin"


export DOCKER_BUILDKIT=1

# Add composer bin directory to PATH
export PATH="$HOME/.config/composer/vendor/bin:$PATH"

# Allow php-cs-fixer to work with PHP 8.4
export PHP_CS_FIXER_IGNORE_ENV=1
export ENV=dev

# Spark 
export SPARK_HOME=~/.local/spark
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin

# Kafka
export KAFKA_HOME=~/.local/kafka
export PATH=$PATH:$KAFKA_HOME/bin:$KAFKA_HOME/bin

# Drill
export DRILL_HOME=~/.local/drill
export PATH=$PATH:$DRILL_HOME/bin:$DRILL_HOME/bin

# Airflow
export AIRFLOW_HOME=~/airflow
export AIRFLOW__WEBSERVER__WEB_SERVER_PORT=8081

# Zeppelin
export ZEPPELIN_HOME=~/.local/zeppelin
export PATH=$PATH:$ZEPPELIN_HOME/bin:$ZEPPELIN_HOME/bin

# Zoxide
eval "$(zoxide init bash)"

export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
export API_TIMEOUT_MS=600000
export ANTHROPIC_MODEL=deepseek-chat
export ANTHROPIC_SMALL_FAST_MODEL=deepseek-chat
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
export PATH="$PATH:$HOME/go/bin"
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS' --color=fg:#ffffff,bg:#161616,hl:#08bdba --color=fg+:#f2f4f8,bg+:#262626,hl+:#3ddbd9 --color=info:#78a9ff,prompt:#33b1ff,pointer:#42be65 --color=marker:#ee5396,spinner:#ff7eb6,header:#be95ff'

stopwatch() {
    start=$(date +%s)
    while true; do
        time="$(($(date +%s) - $start))"
        printf "\r%s" "$(date -u -d "@$time" +%H:%M:%S)"
        sleep 0.1
    done
}
