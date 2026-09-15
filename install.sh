#!/usr/bin/env bash
set -e

echo "== POM-2 dotfiles installer =="

# Paquetes base
PKGS=(hyprland waybar rofi fish fastfetch imv zathura mpv thunar papirus-icon-theme quickshell stow)
sudo pacman -S --needed "${PKGS[@]}"

# papirus-folders (AUR, requiere yay/paru)
if ! command -v papirus-folders &>/dev/null; then
    yay -S --needed papirus-folders-git
fi

# Symlinks con stow
stow -t "$HOME" config
stow -t "$HOME" local

# Driver WiFi fix
sudo cp modprobe.d/rtw88.conf /etc/modprobe.d/rtw88.conf

# Fuente de iconos custom
mkdir -p "$HOME/.local/share/fonts"
cp fonts/*.ttf "$HOME/.local/share/fonts/"
fc-cache -f

# Iconos Papirus verde
papirus-folders -C green 2>/dev/null || echo "papirus-folders no instalado, saltando."

sudo mkinitcpio -P

echo ""
echo "Listo. Reiniciá para aplicar el driver WiFi y las fuentes."
