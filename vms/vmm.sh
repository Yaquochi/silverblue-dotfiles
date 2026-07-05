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
