#!/usr/bin/env bash
set -euo pipefail

# ===== Configurable defaults / flags =========================================
# Set INSTALL_NO_ROOT_PASSWD=1 to skip the root password prompt if your flake
# sets user passwords (users.mutableUsers = false; or hashedPassword set).
INSTALL_NO_ROOT_PASSWD="${INSTALL_NO_ROOT_PASSWD:-0}"

# Set NONINTERACTIVE=1 to skip the confirmation prompt.
NONINTERACTIVE="${NONINTERACTIVE:-0}"

# ============================================================================

usage() {
  cat <<'USAGE'
Usage:
  install.sh <DEVICE> <EFI_PART> <ROOT_PART> <FLAKE> <CONFIG_NAME>

Example:
  install.sh /dev/nvme0n1 /dev/nvme0n1p1 /dev/nvme0n1p2 github:owner/repo my-hostname

This WILL:
  - wipe filesystem signatures on <EFI_PART> and <ROOT_PART>
  - format EFI as FAT32 (label: EFI)
  - format ROOT as ext4  (label: nixos)
  - mount ROOT at /mnt and EFI at /mnt/boot
  - run: nixos-install --flake "<FLAKE>#<CONFIG_NAME>"

Env flags:
  NONINTERACTIVE=1        # do not show destructive confirmation
  INSTALL_NO_ROOT_PASSWD=1  # pass --no-root-passwd to nixos-install

Notes:
  - Run from the NixOS minimal ISO (as root or with sudo).
  - Requires working network (to fetch the GitHub flake).
USAGE
}

# Root check (works whether piping or saved locally)
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Please run as root (e.g., prefix with sudo)." >&2
  exit 1
fi

if [[ ${1:-} == "-h" || ${1:-} == "--help" || $# -ne 5 ]]; then
  usage
  exit 1
fi

DEVICE="$1"
EFI_PART="$2"
ROOT_PART="$3"
FLAKE="$4"
CONFIG_NAME="$5"

# Basic sanity checks
for path in "$DEVICE" "$EFI_PART" "$ROOT_PART"; do
  if [[ ! -b "$path" ]]; then
    echo "Block device not found: $path" >&2
    exit 1
  fi
done

# Make sure partitions look like they belong to the device (best-effort check)
case "$DEVICE" in
  /dev/nvme*) devprefix="${DEVICE}p" ;;
  *)          devprefix="${DEVICE}"  ;;
esac

if [[ "${EFI_PART}" != ${devprefix}* || "${ROOT_PART}" != ${devprefix}* ]]; then
  echo "Warning: ${EFI_PART} or ${ROOT_PART} may not belong to ${DEVICE}." >&2
fi

echo "==> Install plan"
echo "    Device:         $DEVICE"
echo "    EFI partition:  $EFI_PART  (format: FAT32, label: EFI)"
echo "    Root partition: $ROOT_PART (format: ext4,  label: nixos)"
echo "    Flake:          $FLAKE"
echo "    Config name:    $CONFIG_NAME"
if [[ -d /sys/firmware/efi ]]; then
  echo "    Firmware:       UEFI detected"
else
  echo "    Firmware:       Legacy BIOS (no /sys/firmware/efi)"
fi
echo

if [[ "$NONINTERACTIVE" != "1" ]]; then
  read -r -p "Proceed and ERASE the two partitions above? [y/N] " ans
  case "${ans:-}" in
    y|Y|yes|YES) ;;
    *) echo "Aborted."; exit 1 ;;
  esac
fi

# Gentle network check
if ping -c1 -W2 github.com >/dev/null 2>&1; then
  echo "==> Network OK (github.com reachable)"
else
  echo "!!  Warning: github.com not reachable. Ensure networking is up before install."
fi

echo "==> Unmounting any previous mounts under /mnt (best-effort)"
umount -R /mnt 2>/dev/null || true

echo "==> Wiping filesystem signatures"
wipefs -af "$EFI_PART"
wipefs -af "$ROOT_PART"

echo "==> Formatting EFI partition as FAT32"
mkfs.fat -F32 -n EFI "$EFI_PART"

echo "==> Formatting ROOT partition as ext4"
mkfs.ext4 -F -L nixos "$ROOT_PART"

echo "==> Mounting ROOT at /mnt"
mount "$ROOT_PART" /mnt

echo "==> Creating and mounting /mnt/boot (EFI)"
mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot

# Enable flakes for this process without touching config files
export NIX_CONFIG="experimental-features = nix-command flakes"

echo "==> Running nixos-install from flake: ${FLAKE}#${CONFIG_NAME}"
if [[ "$INSTALL_NO_ROOT_PASSWD" == "1" ]]; then
  nixos-install --flake "${FLAKE}#${CONFIG_NAME}" --no-root-passwd
else
  nixos-install --flake "${FLAKE}#${CONFIG_NAME}"
fi

echo "==> Installation complete."
echo "Next steps:"
echo "  umount -R /mnt"
echo "  reboot"
