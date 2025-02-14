[[ -f ~/.bashrc ]] && . ~/.bashrc
. "$HOME/.cargo/env"
export PATH="$HOME/.phpenv/bin:$PATH"
eval "$(rbenv init - bash)"
export PATH="$HOME/flutter-development/flutter/bin:$PATH"' >> ~/.bash_profile
