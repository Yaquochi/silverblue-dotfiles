#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
test -x /usr/bin/python3
test -x /usr/bin/paplay
python3 make-ready-tone.py "${XDG_DATA_HOME:-$HOME/.local/share}/sounds/handy-ready.wav"
install -Dm755 handy-ready-sound "$HOME/.local/bin/handy-ready-sound"
install -Dm644 handy-ready-sound.service "$HOME/.config/systemd/user/handy-ready-sound.service"
systemctl --user daemon-reload
systemctl --user enable handy-ready-sound.service
systemctl --user restart handy-ready-sound.service
