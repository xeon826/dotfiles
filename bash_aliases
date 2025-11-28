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
alias connect-to-phone='adb connect 192.168.1.144:37355';
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
alias nv='nvim'
alias django-ipython='python manage.py shell -i ipython'
alias pip-i='pip install -r requirements.txt'
alias ..='cd ..'
alias ...='cd ../../../'
alias ....='cd ../../../../'
alias .....='cd ../../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../..'
alias vi=vim

# meta input demo website
alias update-cv-kit-demo-website="gcloud compute scp --recurse ./build/* \"meta-input\":~/build --zone \"us-central1-f\" --project \"pict-app\""

alias icat="kitty +kitten icat"
# map f1 launch --type=overlay bash -i -c 'rg "^\s*(map|mouse_map)\s+.*" ~/.config/kitty/kitty.conf | fzf'
alias run-android-emu='emulator -avd Medium_Phone_API_35'
alias scaffold-flutter='flutter pub get; dart run build_runner build --delete-conflicting-outputs; flutter run -d emulator-5554'


alias run-app='flutter run --flavor dev --target lib/main_dev.dart -d emulator-5554'
alias talk-to-robot='pyenv shell 3.12; open-webui serve --port 8084'
alias update-mirrors='sudo reflector --protocol https --verbose --latest 25 --sort rate --save /etc/pacman.d/mirrorlist'
alias listen-to-me='activate ~/git_clones/resumai; python ~/git_clones/resumai/manage.py listen_stream --device-name "HD Webcam C525 Mono"'
alias listen-to-them='activate ~/git_clones/resumai; python ~/git_clones/resumai/manage.py listen_stream --device-name "SteelSeries Arctis Nova 5 Digital Stereo (IEC958)"'
alias lsd='ls -lt --reverse'
alias kafka-list-topics='kafka-topics.sh --list --bootstrap-server localhost:9092'
alias airflow-standalone='AIRFLOW__WEBSERVER__WEB_SERVER_PORT=8082 airflow standalone'
alias test-dag='AIRFLOW_CONFIG=config/airflow/airflow.cfg airflow dags test arxiv_processing 2025-04-27'
alias check-my-ip='curl --socks5-hostname 127.0.0.1:9050 http://checkip.amazonaws.com/'
alias ft='cd /home/dan/git_clones/FreeTube; yarn run dev'
alias newip='tor-prompt --run "SIGNAL NEWNYM"'
alias play-most-recent='ls -rt1 . | tail -n 30 | tr "\n" "\0" | xargs -0 mpv --no-video'
alias serena-generate-config="uvx --from git+https://github.com/oraios/serena serena project generate-yml"
alias clear='clear && printf "\033c"'

alias flushdb="poetry run python -m suno_backend.manage migrate"
alias ytdl="yt-dlp --cookies-from-browser firefox $1"
alias clone="git clone"
alias jellyfin="flatpak run org.jellyfin.JellyfinServer"
alias ncdu='sudo TERM=xterm-256color ncdu'
alias screensoff='xset dpms force off'
alias jelly-mpv-shim='flatpak run com.github.iwalton3.jellyfin-mpv-shim'
