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
    $CMD apk add git bash bash-completion mandoc mandoc-apropos docs icu-data-full musl-locales lang || exit 1
    echo "Installation of security packages"
    $CMD apk add net-tools ufw audit shadow logrotate || exit 1
    echo "Installation of custom apps packages"
    $CMD apk add nano htop bat dust fastfetch alacritty font-meslo-nerd greetd greetd-agreety mako keepassxc keepassxc-lang openssh || exit 1
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
chmod +x /usr/local/bin/sway-run

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
cp config ~/.config/sway

# Enable firewall
$CMD ufw enable
$CMD rc-update add ufw

# Last print
echo "Execution success, please reboot for changes to take effect"
echo "For the wallpaper, just replace ~/.wallpaper.png"