#!/bin/bash

### Initialisation ###

# OS Flavour
if [ -f /etc/os-release ]; then
    source /etc/os-release
fi

# Function to install dependencies for Alpine
install_alpine() {
    echo "Installation of sway desktop"
    $CMD setup-desktop sway || exit 1
    echo "Installation of needed packages"
    $CMD apk add git bash bash-completion mandoc mandoc-apropos docs icu-data-full musl-locales lang mako greetd greetd-agreety || exit 1
    echo "Installation of security packages"
    $CMD apk add net-tools ufw audit shadow logrotate || exit 1
    echo "Installation of custom apps packages"
    $CMD apk add iproute2 drill vim htop bat dust fastfetch alacritty pcmanfm gvfs font-meslo-nerd keepassxc keepassxc-lang openssh-client || exit 1
}

if [ "$ID" == "alpine" ]; then
    echo "Detected Alpine Linux"
    CMD="doas "
    echo "Installing Dependencies using apk"
    install_alpine
else
    echo "Distribution not found / Unsupported distribution"
    exit 1
fi

# Add french langage support
echo 'LANG=fr_FR.UTF-8
LC_CTYPE=fr_FR.UTF-8
LC_NUMERIC=fr_FR.UTF-8
LC_TIME=fr_FR.UTF-8
LC_COLLATE=fr_FR.UTF-8
LC_MONETARY=fr_FR.UTF-8
LC_MESSAGES=fr_FR.UTF-8
LC_ALL=' | $CMD tee -a /etc/profile.d/99fr.sh

# Configure greetd autologin
echo '[initial_session]
command = "/usr/local/bin/sway-run"
user = "$USER"' | $CMD tee -a /etc/greetd/config.toml

# Create sway init script
echo '#! /bin/sh
# Session
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=sway
export XDG_CURRENT_DESKTOP=sway

# Wayland stuff
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export SDL_VIDEODRIVER=wayland
export _JAVA_AWT_WM_NONREPARENTING=1

# Launch Sway with a D-Bus server
exec dbus-run-session sway "$@"' | $CMD tee -a /usr/local/bin/sway-run

# Make it executable
$CMD chmod +x /usr/local/bin/sway-run

# Copy alacritty conf
echo '[window]
blur = true
opacity = 0.6

[font]
normal.family = "MesloLGS Nerd Font Mono"
normal.style = "Regular"
size = 16.0

[font.bold]
family = "MesloLGS Nerd Font Mono"
style = "Bold"

[font.italic]
family = "MesloLGS Nerd Font Mono"
style = "Italic"' > ~/.alacritty.toml

# Copy config file
mkdir -p ~/.config/sway
cp config ~/.config/sway

# Copy bashrc
echo '# Umask
umask 027

# Aliases
alias l="ls -lrth"
alias ll="l -a"

# Prompt
PS1="(\[\e[33m\]\A\[\e[0m\]) \[\e[32m\]\u\[\e[34m\]@\[\e[35m\]\h \[\e[34m\]\W \[\e[36m\]\$\[\e[0m\] "' > ~/.bashrc

# Copy root bashrc
echo '# Umask
umask 027

# Aliases
alias l="ls -lrth"
alias ll="l -a"

# Prompt
PS1="(\[\e[33m\]\A\[\e[0m\]) \[\e[5m\]\[\e[31m\]\u\[\e(B\[\e[m\]\[\e[34m\]@\[\e[35m\]\h \[\e[34m\]\W \[\e[31m\]#\[\e[0m\] "' | $CMD tee -a /root/.bashrc

# Copy pcmanfm conf
mkdir -p ~/.config/pcmanfm/default
echo '[config]
bm_open_method=0

[volume]
mount_on_startup=0
mount_removable=0
autorun=0

[ui]
always_show_tabs=0
max_tab_chars=32
win_width=1870
win_height=1007
splitter_pos=150
media_in_new_tab=0
desktop_folder_new_win=0
change_tab_on_drop=1
close_on_unmount=0
focus_previous=0
side_pane_mode=places
view_mode=icon
show_hidden=0
sort=name;ascending;
toolbar=newtab;navigation;home;
show_statusbar=1
pathbar_mode_buttons=0' > ~/.config/pcmanfm/default/pcmanfm.conf

# Enable firewall
$CMD ufw enable
$CMD rc-update add ufw

# Fix permissions
chmod -R o-rwx ~
$CMD chmod -R o-rwx /root

# Enable poweroff as wheel without password
echo 'permit nopass :wheel as root cmd /sbin/poweroff' | $CMD tee -a /etc/doas.d/30-poweroff.conf

# Systcl conf
if [ ! -f /etc/sysctl.d/no-ipv6.conf ]; then
    echo 'net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1' | $CMD tee -a /etc/sysctl.d/no-ipv6.conf
fi

echo 'net.ipv4.ip_forward = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0' | $CMD tee -a /etc/sysctl.d/secure.conf

# Last print
echo "Execution success, please reboot for changes to take effect"
echo "For the wallpaper, just replace ~/.wallpaper.png"
