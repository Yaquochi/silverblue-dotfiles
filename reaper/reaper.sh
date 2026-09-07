#!/usr/bin/env bash
#
# silverblue-dotfiles/reaper/install.sh
#
# Установка нативного REAPER в ~/opt/REAPER на Fedora Silverblue.
# Системный образ rpm-ostree не изменяется.
#
# Во время запуска ./install-reaper.sh выбрать:
#
#   Command [V,R,I,A]: I
#
#   Path to install [1,2, or /whatever]: 2
#     -> установка в ~/opt/REAPER
#
#   Would you like to add desktop integration [Y/N]?: Y
#     -> добавить REAPER в меню приложений GNOME
#
#   Would you like to symlink /usr/local/bin/reaper ... [Y/N]?: N
#     -> НЕ создаём системный symlink.
#        Скрипт сам создаст ~/.local/bin/reaper без sudo.
#
#   Proceed with installation [Y/N]?: Y
#
# После установки в REAPER:
#
#   Options -> Preferences -> Audio -> Device
#
#   Audio system: JACK
#   Input channels: 2
#   Output channels: 2
#
#   [ ] Auto-start jackd
#   [x] Auto-connect jack audio channels to hardware
#   [ ] Auto-connect jack MIDI channels to hardware   # если MIDI не нужен
#   [ ] Auto-suspend PulseAudio
#
#   RT priority: automatic from JACK
#
# PipeWire должен управлять sample rate / quantum.
# Для текущей конфигурации:
#
#   48000 Hz
#   quantum 128
#
# Стандартные пользовательские директории плагинов:
#
#   VST2 -> ~/.vst
#   VST3 -> ~/.vst3
#   LV2  -> ~/.lv2
#   CLAP -> ~/.clap
#
# Для установки обычных пользовательских плагинов sudo не нужен.

set -euo pipefail

REAPER_VERSION="779"
ARCHIVE="reaper${REAPER_VERSION}_linux_x86_64.tar.xz"
URL="https://www.reaper.fm/files/7.x/${ARCHIVE}"

TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

echo "==> Проверка PipeWire JACK"

if rpm -q pipewire-jack-audio-connection-kit >/dev/null 2>&1 &&
   rpm -q pipewire-jack-audio-connection-kit-libs >/dev/null 2>&1 &&
   command -v pw-jack >/dev/null 2>&1; then
    echo "PipeWire JACK уже установлен."
else
    echo
    echo "PipeWire JACK не найден."
    echo "На Silverblue установи его отдельно:"
    echo
    echo "  sudo rpm-ostree install pipewire-jack-audio-connection-kit"
    echo "  systemctl reboot"
    echo
    exit 1
fi

echo
echo "==> Создание пользовательских директорий"

mkdir -p \
    "${HOME}/opt" \
    "${HOME}/.local/bin" \
    "${HOME}/.vst" \
    "${HOME}/.vst3" \
    "${HOME}/.lv2" \
    "${HOME}/.clap"

echo
echo "==> Скачивание REAPER ${REAPER_VERSION}"

curl \
    --fail \
    --location \
    --progress-bar \
    "${URL}" \
    --output "${TMP_DIR}/${ARCHIVE}"

echo
echo "==> Распаковка"

tar -xf "${TMP_DIR}/${ARCHIVE}" -C "${TMP_DIR}"

echo
echo "============================================================"
echo "В установщике выбери:"
echo
echo "  I  -> Install REAPER"
echo "  2  -> Install to ~/opt/REAPER"
echo "  Y  -> Desktop integration"
echo "  N  -> НЕ создавать /usr/local/bin/reaper"
echo "  Y  -> Proceed with installation"
echo "============================================================"
echo

cd "${TMP_DIR}/reaper_linux_x86_64"
./install-reaper.sh

if [[ ! -x "${HOME}/opt/REAPER/reaper" ]]; then
    echo
    echo "Ошибка: ${HOME}/opt/REAPER/reaper не найден."
    echo "Проверь, что в установщике был выбран пункт 2."
    exit 1
fi

echo
echo "==> Создание пользовательской команды reaper"

ln -sfn \
    "${HOME}/opt/REAPER/reaper" \
    "${HOME}/.local/bin/reaper"

echo
echo "==> Проверка"

echo "REAPER:"
readlink -f "${HOME}/.local/bin/reaper"

echo
echo "PipeWire:"
pw-metadata -n settings 2>/dev/null |
    grep -E "clock\.(rate|allowed-rates|quantum|min-quantum|max-quantum)" ||
    true

echo
echo "============================================================"
echo "REAPER установлен."
echo
echo "Запуск:"
echo
echo "  reaper"
echo
echo "Установлен в:"
echo
echo "  ~/opt/REAPER"
echo
echo "Плагины:"
echo
echo "  ~/.vst"
echo "  ~/.vst3"
echo "  ~/.lv2"
echo "  ~/.clap"
echo "============================================================"
