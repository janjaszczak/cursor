#!/bin/bash
# Platform detection and native secret store (bash/Linux/WSL only).

keepass_platform() {
    if grep -qiE 'microsoft|WSL' /proc/version 2>/dev/null; then
        echo "wsl"
    else
        echo "linux"
    fi
}

keepass_ensure_secret_tool() {
    if command -v secret-tool >/dev/null 2>&1; then
        return 0
    fi
    echo "Brak secret-tool (natywny keyring Linux/WSL). Instalacja: sudo apt install -y libsecret-tools gnome-keyring dbus-x11" >&2
    if command -v apt-get >/dev/null 2>&1; then
        if sudo -n true 2>/dev/null; then
            sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq libsecret-tools gnome-keyring dbus-x11
        else
            echo "Agent: poproś użytkownika o sudo apt install libsecret-tools gnome-keyring dbus-x11, potem ponów." >&2
            return 1
        fi
    else
        echo "Agent: zainstaluj pakiet libsecret-tools (menedżer pakietów dystrybucji)." >&2
        return 1
    fi
    command -v secret-tool >/dev/null 2>&1
}
