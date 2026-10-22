#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
test "$EUID" -eq 0

# Сначала прочитай README.md с командами отката.
# Нужна стандартная NAT-сеть libvirt с мостом virbr0.
ip link show virbr0 >/dev/null
test -z "$(ip -4 route show table 200 2>/dev/null)"
test -z "$(ip -4 rule show | grep -E '^(100|101):' || true)"
test -z "$(ip -6 rule show | grep -E '^(100|101):' || true)"
test ! -e /etc/systemd/system/vm-direct-network.service
test ! -e /etc/NetworkManager/dispatcher.d/90-vm-direct-network
if nft list table ip vm_direct_network >/dev/null 2>&1; then
    echo 'Таблица vm_direct_network уже существует. Сначала проверь её и выполни откат.'
    exit 1
fi

# Снимок для диагностики. Полный firewall назад не загружаем.
install -d -m 700 /var/lib/vm-direct-network
ip -4 rule show > /var/lib/vm-direct-network/rules4.before
ip -6 rule show > /var/lib/vm-direct-network/rules6.before
ip -4 route show table all > /var/lib/vm-direct-network/routes4.before
nft list ruleset > /var/lib/vm-direct-network/firewall.before

install -D -m 755 apply.sh /usr/local/libexec/vm-direct-network
install -D -m 755 rollback.sh /usr/local/sbin/vm-direct-network-rollback
cat > /etc/systemd/system/vm-direct-network.service <<'EOF'
[Unit]
Description=Direct network for libvirt virbr0
After=NetworkManager-wait-online.service libvirtd.service virtnetworkd.service
Wants=NetworkManager-wait-online.service

[Service]
Type=oneshot
ExecStart=/usr/local/libexec/vm-direct-network

[Install]
WantedBy=multi-user.target
EOF

# При смене Wi-Fi/кабеля обновить шлюз; соединения хоста не перезапускаются.
cat > /etc/NetworkManager/dispatcher.d/90-vm-direct-network <<'EOF'
#!/usr/bin/env bash
case "$2" in
    up|down|dhcp4-change) systemctl start --no-block vm-direct-network.service ;;
esac
EOF
chmod 755 /etc/NetworkManager/dispatcher.d/90-vm-direct-network
systemctl daemon-reload
systemctl enable vm-direct-network.service
systemctl start vm-direct-network.service
