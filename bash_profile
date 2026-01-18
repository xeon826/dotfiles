[[ -f ~/.bashrc ]] && . ~/.bashrc
. "$HOME/.cargo/env"
export PATH="$HOME/.phpenv/bin:$PATH"
export PATH="$HOME/flutter-development/flutter/bin:$PATH" >> ~/.bash_profile

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[ -f /home/dan/.dart-cli-completion/bash-config.bash ] && . /home/dan/.dart-cli-completion/bash-config.bash || true
## [/Completion]


. "$HOME/.local/bin/env"
