#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./setup-data-disk.sh /dev/nvme0n1
#
# WARNING:
#   This script completely erases the selected disk.

MOUNTPOINT="/var/mnt/data"
LABEL="data"
BTRFS_OPTS="defaults,noatime,compress=zstd:1,nofail,x-systemd.device-timeout=10s"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /dev/nvmeXnY"
  echo
  echo "Available disks:"
  lsblk -e7 -o NAME,PATH,MODEL,SERIAL,SIZE,TYPE,FSTYPE,LABEL,UUID,MOUNTPOINTS
  exit 1
fi

DISK="$1"

if [[ ! -b "$DISK" ]]; then
  echo "ERROR: $DISK is not a block device"
  exit 1
fi

DISK_TYPE="$(lsblk -dn -o TYPE "$DISK")"

if [[ "$DISK_TYPE" != "disk" ]]; then
  echo "ERROR: $DISK is not a whole disk"
  echo "Use disk path like /dev/nvme0n1, not partition path like /dev/nvme0n1p1"
  exit 1
fi

for cmd in lsblk wipefs sfdisk blockdev udevadm mkfs.btrfs blkid findmnt mount systemctl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $cmd"
    exit 1
  fi
done

echo "Selected disk:"
lsblk -e7 -o NAME,PATH,MODEL,SERIAL,SIZE,TYPE,FSTYPE,LABEL,UUID,MOUNTPOINTS "$DISK"
echo

if lsblk -nr -o MOUNTPOINTS "$DISK" | grep -q '[^[:space:]]'; then
  echo "ERROR: $DISK or one of its partitions is mounted."
  echo "Refusing to continue."
  exit 1
fi

echo "This will ERASE ALL DATA on: $DISK"
echo
echo "Type exactly this to continue:"
echo "ERASE $DISK"
read -r CONFIRM

if [[ "$CONFIRM" != "ERASE $DISK" ]]; then
  echo "Aborted."
  exit 1
fi

echo
echo "Wiping existing filesystem and partition signatures..."
sudo wipefs -a "$DISK"

echo
echo "Creating GPT partition table and one Linux filesystem partition..."
sudo sfdisk "$DISK" <<'EOF'
label: gpt
, , 0FC63DAF-8483-4772-8E79-3D69D8477DE4
EOF

sudo blockdev --rereadpt "$DISK" || true
sudo udevadm settle

PART="$(lsblk -nr -o PATH "$DISK" | sed -n '2p')"

if [[ -z "${PART:-}" || ! -b "$PART" ]]; then
  echo "ERROR: failed to detect created partition"
  lsblk -f "$DISK"
  exit 1
fi

echo
echo "Created partition: $PART"

echo
echo "Removing old signatures from partition..."
sudo wipefs -a "$PART"

echo
echo "Formatting as Btrfs..."
sudo mkfs.btrfs -f -L "$LABEL" "$PART"

UUID="$(sudo blkid -s UUID -o value "$PART")"

if [[ -z "$UUID" ]]; then
  echo "ERROR: failed to get UUID for $PART"
  exit 1
fi

echo
echo "Filesystem UUID: $UUID"

echo
echo "Creating mountpoint: $MOUNTPOINT"
sudo mkdir -p "$MOUNTPOINT"

FSTAB_LINE="UUID=$UUID $MOUNTPOINT btrfs $BTRFS_OPTS 0 0"

if grep -qE "[[:space:]]$MOUNTPOINT[[:space:]]" /etc/fstab; then
  echo
  echo "ERROR: /etc/fstab already contains an entry for $MOUNTPOINT"
  echo "Edit /etc/fstab manually before running this script again."
  exit 1
fi

echo
echo "Adding to /etc/fstab:"
echo "$FSTAB_LINE"
echo "$FSTAB_LINE" | sudo tee -a /etc/fstab >/dev/null

echo
echo "Testing mount..."
sudo systemctl daemon-reload
sudo mount -a

if ! findmnt "$MOUNTPOINT" >/dev/null 2>&1; then
  echo "ERROR: mount failed"
  exit 1
fi

echo
echo "Setting ownership to current user..."
sudo chown "$USER:$USER" "$MOUNTPOINT"

echo
echo "Testing write access..."
touch "$MOUNTPOINT/testfile"
rm "$MOUNTPOINT/testfile"

echo
echo "Done."
echo
findmnt "$MOUNTPOINT"
df -h "$MOUNTPOINT"
