#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

gsettings set org.gnome.desktop.interface enable-animations false

flatpak uninstall -y --delete-data org.gnome.Characters
flatpak uninstall -y --delete-data org.gnome.Contacts
flatpak uninstall -y --delete-data org.gnome.Extensions

sudo rpm-ostree override remove \
  gnome-tour \
  gnome-system-monitor \
  malcontent-control \
  ptyxis \
  yelp \
  yelp-libs \
  yelp-xsl \
  ibus-anthy \
  ibus-anthy-python \
  anthy-unicode \
  kasumi-unicode \
  ibus-libpinyin \
  libpinyin \
  libpinyin-data \
  ibus-typing-booster \
  firefox firefox-langpacks \
  firefox

sudo rpm-ostree install \
  alacritty \
  tmux \
  vim \
  btop \
  gnome-tweaks -y

wget https://files.stirlingpdf.com/linux-installer.rpm
sudo rpm-ostree install ./linux-installer.rpm -y
rm linux-installer.rpm

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak remote-modify --enable flathub

flatpak install -y flathub com.mattjakeman.ExtensionManager
# Download in extension manager: 
# 1) PaperWM
# 2) Workspaces indicator by open apps
# 3) AppIndicator and KStatusNotifierItem Support
# 4) Clipboard Indicator
# 5) Blur my Shell
gnome-extensions enable paperwm@paperwm.github.com
gnome-extensions enable workspaces-by-open-apps@favo02.github.com
gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com
gnome-extensions enable clipboard-indicator@tudmotu.com
gnome-extensions enable blur-my-shell@aunetx

flatpak install -y flathub net.waterfox.waterfox
flatpak install -y flathub com.github.tchx84.Flatseal

flatpak install -y flathub org.gimp.GIMP
flatpak install -y flathub org.kde.kdenlive
flatpak install -y flathub org.audacityteam.Audacity
flatpak install -y flathub com.obsproject.Studio
flatpak install -y flathub io.mpv.Mpv
flatpak install -y flathub org.atheme.audacious
flatpak install -y flathub com.github.wwmm.easyeffects

flatpak install -y flathub org.onlyoffice.desktopeditors
flatpak install -y flathub org.zotero.Zotero
flatpak install -y flathub com.github.johnfactotum.Foliate
flatpak install -y flathub md.obsidian.Obsidian
flatpak install -y flathub org.jamovi.jamovi
flatpak install -y flathub com.rafaelmardojai.Blanket

flatpak install -y flathub org.qbittorrent.qBittorrent
flatpak install -y flathub org.localsend.localsend_app
flatpak install -y flathub me.kozec.syncthingtk
flatpak install -y flathub io.github.peazip.PeaZip

flatpak install -y flathub org.telegram.desktop
flatpak install -y flathub com.discordapp.Discord
flatpak install -y flathub org.signal.Signal

cp -v ./bash/.bashrc ~/.bashrc
cp -v ./bash/.dircolors ~/.dircolors

mkdir -p ~/.local/share/fonts
cp -rv ./fonts/* ~/.local/share/fonts/
fc-cache -f -v

mkdir -p ~/.config/alacritty
cp -rv ./alacritty/* ~/.config/alacritty/

mkdir -p ~/.config/tmux
cp -rv ./tmux/* ~/.config/tmux/

cp -v ./vim/.vimrc ~/.vimrc 2>/dev/null || true

mkdir -p ~/.config/k9s
cp -rv ./k9s/* ~/.config/k9s/ 2>/dev/null || true

mkdir -p ~/Pictures
cp -rv ./pics/* ~/Pictures/

mkdir -p ~/.config/pipewire/pipewire.conf.d
cp ./sound/10-lowlatency.conf ~/.config/pipewire/pipewire.conf.d
systemctl --user restart pipewire pipewire-pulse wireplumber

dconf load /org/gnome/desktop/wm/keybindings/ < ./keybinds/wm-keys.txt
dconf load /org/gnome/settings-daemon/plugins/media-keys/ < ./keybinds/media-keys.txt
dconf load /org/gnome/mutter/keybindings/ < ./keybinds/mutter-keys.txt
dconf load /org/gnome/mutter/wayland/keybindings/ < ./keybinds/mutter-wayland-keys.txt
dconf load /org/gnome/shell/keybindings/ < ./keybinds/shell-keys.txt

mkdir -p ~/.local/bin
curl https://mise.run | MISE_INSTALL_PATH="$HOME/.local/bin/mise" sh
export PATH="$HOME/.local/bin:$PATH"
source ~/.bashrc
cd ~
mise use -g kubectl@latest
mise use -g helm@latest
mise use -g k9s@latest
mise use -g hunk@latest
mise use -g yazi@latest

sudo rpm-ostree upgrade
flatpak update -y
mise upgrade

systemctl reboot -i
