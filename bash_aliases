# vagrant
alias store_code_login="ssh -p 2222 -X pictpod@127.0.0.1"
alias redo_vagrant='vagrant halt; vagrant destroy -f; vagrant up'
alias s="ssh -p 2222 -X pictpod@127.0.0.1"

# sw 
alias reinstall_pip_packages_use_dep='deactivate; rm -rf venv; python -m venv venv; source venv/bin/activate; pip install -r webapp/requirements.txt --use-deprecated=legacy-resolver'
alias reinstall_pip_packages='source deactivate; rm -rf webapp/venv; python -m venv webapp/venv; source webapp/venv/bin/activate; pip install -r webapp/requirements.txt'
alias set_test4_gcloud='export GOOGLE_APPLICATION_CREDENTIALS="/home/dan/test4-google-credentials.json"'

# docker
alias clean_docker='docker system prune -a -f'
alias docker_clean_ps='docker rm $(docker ps --filter=status=exited --filter=status=created -q)'
alias dc='docker-compose'
alias sshc="docker exec -it c15f9c0f259a bash"
alias down='docker-compose down'
alias upb='docker-compose up -d --build'
alias up='docker-compose up -d'

# xclip
alias clipboard_in='xclip -sel clip'
alias clipboard_out='xclip -o'

# folder size
alias show_diskspace='df -h'
alias get_folder_sizes='sudo du -cha --max-depth=1 . | grep -E "M|G"'

#lxc
alias store-log-external='lxc exec store -- watch -n 1 tail -n 50 /var/log/cloud-init-output.log'
alias to-store='lxc exec my-ubuntu-vm -- su - pictpod'

# misc
alias lutris='pyenv shell system; lutris -d'
alias dev_server_tsx='truncate -s 0 output.txt; npm start >> output.txt 2>&1'
alias to_gcloud_vm='gcloud compute ssh --zone "us-central1-a" "stockwell-image-host" --project "pict-app"'
alias rg='rg -s'
alias r='python main.py'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias loopback-audio-for-steamlink="pw-loopback --capture-props='media.class=Audio/Sink' --playback-props='node.name=steamlink_sink'"
alias rvm='rbenv'
alias epsxe-scrcpy='scrcpy -f --crop 1080:1920:0:380'
alias connect-to-dualsense='bluetoothctl remove 58:10:31:97:44:BE; bluetoothctl power on; bluetoothctl discoverable on; bluetoothctl scan on; bluetoothctl pair 58:10:31:97:44:BE; bluetoothctl trust 58:10:31:97:44:BE;'
alias connect-to-phone='adb connect 192.168.1.144; scrcpy -f;'
alias connect-to-tjt='TERM=xterm-256color ssh thejkwun@server119.web-hosting.com -p21098;'
alias s='sgpt'
alias s1='sgpt --chat conversation_1'
alias s2='sgpt --chat conversation_2'
alias s3='sgpt --chat conversation_3'
alias cozy='flatpak run com.github.geigi.cozy'
alias pointer-reattach='xinput reattach 9 21'
alias fix-usb='sudo ntfsfix -d /dev/sdb1'
alias django-ipython='python manage.py shell -i ipython'
alias trw='tmux rename-window '
alias x='exit'
alias nv='kitty @ set-window-title "$(realpath --relative-to="$HOME" "$(pwd)")"; nvim'
alias django-ipython='python manage.py shell -i ipython'
alias pip-i='pip install -r requirements.txt'

# meta input demo website
alias update-cv-kit-demo-website="gcloud compute scp --recurse ./build/* \"meta-input\":~/build --zone \"us-central1-f\" --project \"pict-app\""

alias icat="kitty +kitten icat"
