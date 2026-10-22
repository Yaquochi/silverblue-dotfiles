#!/usr/bin/env bash
set -euo pipefail

# Запускается от root. Только стандартная сеть libvirt default (virbr0).
# Таблица 200 и приоритеты 100/101 зарезервированы этим скриптом.
exec 9>/run/vm-direct-network.lock
flock 9

# Запрет ниже маршрута: если прямой интернет исчез, не использовать другие маршруты.
ip -4 rule show | grep -q '^101:.*iif virbr0.*prohibit' || ip -4 rule add priority 101 iif virbr0 prohibit
ip -6 rule show | grep -q '^101:.*iif virbr0.*prohibit' || ip -6 rule add priority 101 iif virbr0 prohibit
ip -4 rule show | grep -q '^100:.*iif virbr0.*lookup 200' || ip -4 rule add priority 100 iif virbr0 lookup 200

# Берём обычный шлюз из основной таблицы main.
# Никакие маршруты самого хоста не меняем.
ip -4 route flush table 200 2>/dev/null || true
DIRECT_ROUTE=$(ip -4 route show table main default | head -n 1)
DIRECT_IF=$(awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' <<< "$DIRECT_ROUTE")
DIRECT_GW=$(awk '{for(i=1;i<=NF;i++) if($i=="via") print $(i+1)}' <<< "$DIRECT_ROUTE")

# На ноутбуке выбираем только Ethernet/Wi-Fi.
DIRECT_TYPE=$(nmcli -g GENERAL.TYPE device show "${DIRECT_IF:-lo}")
if [[ "$DIRECT_TYPE" != wifi && "$DIRECT_TYPE" != ethernet ]]; then
    echo 'Нет прямого Wi-Fi/Ethernet: интернет VM заблокирован.'
    exit 0
fi
test -n "$DIRECT_GW"

# DNS-запросы VM к хосту отправляем DNS домашней сети.
# Корпоративные DNS внутри Debian это правило не затрагивает.
DIRECT_DNS=$(nmcli -g IP4.DNS device show "$DIRECT_IF" | head -n 1)
DIRECT_DNS=${DIRECT_DNS:-$DIRECT_GW}
if ! ip link show virbr0 >/dev/null 2>&1; then
    echo 'Мост virbr0 ещё не запущен. Правила запрета уже установлены.'
    exit 0
fi
VM_GW=$(ip -4 -o address show dev virbr0 | awk '{split($4,a,"/"); print a[1]; exit}')
test -n "$VM_GW"

# Обновление своей таблицы firewall одним атомарным набором команд.
nft add table ip vm_direct_network
nft -f - <<EOF
flush table ip vm_direct_network
add chain ip vm_direct_network dns { type nat hook prerouting priority dstnat; policy accept; }
add rule ip vm_direct_network dns iifname "virbr0" ip daddr $VM_GW udp dport 53 counter dnat to $DIRECT_DNS
add rule ip vm_direct_network dns iifname "virbr0" ip daddr $VM_GW tcp dport 53 counter dnat to $DIRECT_DNS
EOF

# Включаем прямой маршрут последним, после настройки DNS.
ip -4 route add table 200 default via "$DIRECT_GW" dev "$DIRECT_IF" onlink
ip -4 route show table 200
