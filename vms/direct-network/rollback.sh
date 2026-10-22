#!/usr/bin/env bash
set -eu
# Запуск: sudo bash rollback.sh. Настройки хоста не трогаем.
test "$EUID" -eq 0
systemctl disable vm-direct-network.service 2>/dev/null || true
rm -f /etc/NetworkManager/dispatcher.d/90-vm-direct-network
systemctl stop vm-direct-network.service 2>/dev/null || true
ip -4 rule del priority 100 iif virbr0 lookup 200 2>/dev/null || true
ip -4 rule del priority 101 iif virbr0 prohibit 2>/dev/null || true
ip -6 rule del priority 101 iif virbr0 prohibit 2>/dev/null || true
ip -4 route flush table 200 2>/dev/null || true
nft delete table ip vm_direct_network 2>/dev/null || true
rm -f /etc/systemd/system/vm-direct-network.service /usr/local/libexec/vm-direct-network
systemctl daemon-reload
echo 'Исключение VM удалено. Маршрутизация хоста не менялась.'
