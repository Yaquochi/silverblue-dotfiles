# Прямое подключение VM

Для Fedora Silverblue, NetworkManager и стандартной NAT-сети libvirt
`default` с мостом `virbr0`. Действует на все VM этой сети.
Нужны iproute, nftables, util-linux, NetworkManager, systemd.
Адрес Wi-Fi, шлюз и DNS определяются заново на каждом ноутбуке.
Рабочие подключения и DNS внутри Debian остаются под управлением Debian.

## Откат (можно выполнить без интернета)

```bash
sudo bash /var/home/yaquochi/repos/silverblue-dotfiles/vms/direct-network/rollback.sh
```

Или установленная копия:

```bash
sudo /usr/local/sbin/vm-direct-network-rollback
```

Удаляются только наши правила, таблица 200 и таблица nft `vm_direct_network`.
Не выполнять `ip rule flush` или `nft flush ruleset`.
После отката VM снова использует обычную маршрутизацию хоста.

## Установка

Сначала запусти стандартную сеть libvirt (`vmm.sh`), затем:

```bash
sudo bash /var/home/yaquochi/repos/silverblue-dotfiles/vms/direct-network/install.sh
```

Повторная установка останавливается: сначала откат, потом установка.
Таблица 200 и приоритеты 100/101 должны быть свободны.
Другие средства маршрутизации должны использовать приоритеты позже 101
(на проверенном хосте — таблица 2022, приоритеты 9000–9010).
При изменении сетевого ПО нужна повторная проверка.

`apply.sh` — прямые команды настройки без функций.
При отсутствии физического IPv4-шлюза интернет VM блокируется.
IPv6 из virbr0 запрещён; стандартная сеть здесь использует только IPv4.
DNS к адресу хоста перенаправляется на DNS физического подключения.
Локальные имена других VM через DNS libvirt при этом не разрешаются.
Уже установленные DNS-соединения могут сохранять прежний NAT до истечения
conntrack; для проверки используй новый процесс/запрос.

## Проверка

```bash
ip -4 rule show
ip -4 route show table 200
ip -4 route get 1.1.1.1 from 192.168.122.177 iif virbr0
sudo nft list table ip vm_direct_network
ssh workvm 'curl -4 --max-time 15 https://api.ipify.org; echo'
curl -4 --max-time 15 https://api.ipify.org; echo
```

В запросе `route get` замени IP Debian на актуальный адрес VM.
VM должна выходить через провайдера; подключение хоста остаётся прежним.
После смены сети и обновления сетевого ПО повтори проверку.
