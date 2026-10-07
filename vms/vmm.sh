mkdir -p ~/VMs

sudo rpm-ostree install \
  virt-manager \
  virt-viewer \
  virt-install \
  qemu-kvm \
  libvirt-daemon-kvm \
  libvirt-daemon-config-network

systemctl reboot -i

sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt "$USER"

systemctl reboot -i

sudo virsh net-start default
sudo virsh net-autostart default

sudo mkdir -p /etc/polkit-1/rules.d

sudo tee /etc/polkit-1/rules.d/80-libvirt-manage.rules >/dev/null <<'EOF'
polkit.addRule(function(action, subject) {
    if (action.id == "org.libvirt.unix.manage" &&
        subject.local &&
        subject.active &&
        subject.user == "yaquochi") {
        return polkit.Result.YES;
    }
});
EOF

mkdir -p ~/.local/bin/

cat > ~/.local/bin/work <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

VM="debian13"
URI="qemu:///system"

if ! virsh -c "$URI" list --state-running --name | grep -Fxq "$VM"; then
    virsh -c "$URI" start "$VM" >/dev/null
fi

exec virt-viewer \
    --connect "$URI" \
    --attach \
    --reconnect \
    --full-screen \
    --auto-resize=always \
    "$VM"
EOF

chmod +x ~/.local/bin/work
