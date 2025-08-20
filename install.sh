#!/usr/bin/env bash
set -euo pipefail

# ========================= Flags / Defaults =========================
# Skip the destructive confirmation prompt (set to 1 for CI/one-liners)
NONINTERACTIVE="${NONINTERACTIVE:-0}"
# Pass --no-root-passwd to nixos-install (use if your flake defines users/passwords)
INSTALL_NO_ROOT_PASSWD="${INSTALL_NO_ROOT_PASSWD:-0}"
# Case-insensitive replacements/renames for "chase" (0: exact lowercase only, 1: case-insensitive)
CASE_INSENSITIVE_RENAME="${CASE_INSENSITIVE_RENAME:-0}"
# Name token to replace in names & contents
REPLACE_TOKEN="${REPLACE_TOKEN:-chase}"
# Directory patterns to exclude from replacement (space-separated glob fragments)
EXCLUDE_DIRS="${EXCLUDE_DIRS:-.git .direnv result node_modules vendor .cache}"

# ===================================================================

usage() {
  cat <<'USAGE'
Usage:
  install.sh <DEVICE> <EFI_PART> <ROOT_PART> <FLAKE_URL> <CONFIG_NAME> <USER_NAME>

Example:
  install.sh /dev/nvme0n1 /dev/nvme0n1p1 /dev/nvme0n1p2 \
    github:ChaseSunstrom/NixOS-Dotfiles my-hostname myuser

This WILL:
  - wipe filesystem signatures on <EFI_PART> and <ROOT_PART>
  - format EFI as FAT32 (label: EFI)
  - format ROOT as ext4 (label: nixos)
  - fetch the flake into a temp dir (supports github:owner/repo OR local path)
  - replace *names and contents* of all files/dirs containing the token "chase"
      with <USER_NAME> (by default case-sensitive; set CASE_INSENSITIVE_RENAME=1)
  - run: nixos-install --flake <LOCAL_TEMP_PATH>#<CONFIG_NAME>

Environment variables:
  NONINTERACTIVE=1             # skip destructive confirmation prompt
  INSTALL_NO_ROOT_PASSWD=1     # pass --no-root-passwd to nixos-install
  CASE_INSENSITIVE_RENAME=1    # treat "chase" case-insensitively in names/contents
  REPLACE_TOKEN=chase          # change the token being replaced from "chase"
  EXCLUDE_DIRS=".git node_modules ..."  # space-separated folder-globs to skip

Notes:
  - Run from the NixOS minimal ISO as root (or with sudo).
  - Requires networking for remote GitHub flakes.
  - Uses GNU tools available on NixOS ISO (sed, find, xargs, perl recommended).
USAGE
}

need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Please run as root (e.g., prefix with sudo)." >&2
    exit 1
  fi
}

check_args() {
  if [[ ${1:-} == "-h" || ${1:-} == "--help" || $# -ne 6 ]]; then
    usage
    exit 1
  fi
}

confirm_or_die() {
  if [[ "$NONINTERACTIVE" == "1" ]]; then
    return 0
  fi
  echo "==> WARNING: This will ERASE filesystems on:"
  echo "    - EFI : $EFI_PART  (FAT32)"
  echo "    - ROOT: $ROOT_PART (ext4)"
  read -r -p "Proceed? [y/N] " ans
  case "${ans:-}" in
    y|Y|yes|YES) ;;
    *) echo "Aborted."; exit 1 ;;
  esac
}

is_remote_github() {
  [[ "$FLAKE_URL" == github:* ]]
}

clone_flake_to_tmp() {
  local tmp
  tmp="$(mktemp -d)"
  if is_remote_github; then
    local owner_repo="${FLAKE_URL#github:}"  # e.g. ChaseSunstrom/NixOS-Dotfiles
    echo "==> Cloning $owner_repo into $tmp"
    git clone --depth=1 "https://github.com/${owner_repo}.git" "$tmp"
  else
    # local path
    echo "==> Copying local flake from $FLAKE_URL to $tmp"
    # Use rsync if present, else cp -a
    if command -v rsync >/dev/null 2>&1; then
      rsync -a --exclude '.git' "$FLAKE_URL"/ "$tmp"/
    else
      cp -a "$FLAKE_URL"/. "$tmp"/
      rm -rf "$tmp/.git" 2>/dev/null || true
    fi
  fi
  echo "$tmp"
}

# Build a find -prune expression from EXCLUDE_DIRS
build_prune_expr() {
  local expr=()
  for d in $EXCLUDE_DIRS; do
    expr+=( -path "*/$d/*" -o -path "*/$d" )
  done
  # echo combined expression for use with eval
  printf ' \\( %s \\) -prune -o ' "$(printf '%s ' "${expr[@]}" | sed 's/ -o $//')"
}

# Replace contents in files
replace_contents() {
  local root="$1" search="$2" replace="$3" ci="$4"

  echo "==> Replacing token in file contents (ci=${ci}) under: $root"
  local prune
  prune="$(build_prune_expr)"

  # shellcheck disable=SC2016
  # Using -print0/-0 to handle spaces/newlines safely
  if [[ "$ci" == "1" ]]; then
    # case-insensitive (GNU sed supports 'I' flag in s///gI)
    eval "find \"$root\" -type d \\( -name .git -o -name .repo \\) -prune -o -type f $prune -type f -print0" \
      | xargs -0 sed -i -E "s|${search}|$(printf '%s' "$replace" | sed 's/[&/\]/\\&/g')|gI"
  else
    eval "find \"$root\" -type d \\( -name .git -o -name .repo \\) -prune -o -type f $prune -type f -print0" \
      | xargs -0 sed -i -E "s|${search}|$(printf '%s' "$replace" | sed 's/[&/\]/\\&/g')|g"
  fi
}

# Rename paths whose *names* contain the token
rename_paths() {
  local root="$1" search="$2" replace="$3" ci="$4"

  echo "==> Renaming file/dir names (ci=${ci}) under: $root"
  local prune
  prune="$(build_prune_expr)"

  # We go depth-first to rename children before parents
  # Use perl or sed to transform names case-insensitively if requested
  eval "find \"$root\" -depth $prune -print0" | while IFS= read -r -d '' path; do
    # Skip .git and other pruned paths
    for d in $EXCLUDE_DIRS; do
      case "$path" in
        *"/$d"|*"/$d/"* ) continue 2 ;;
      esac
    done

    local base dir newbase
    base="$(basename -- "$path")"
    dir="$(dirname -- "$path")"

    if [[ "$ci" == "1" ]]; then
      # case-insensitive replace in the *name* only
      newbase="$(printf '%s' "$base" | sed -E "s|${search}|$(printf '%s' "$replace" | sed 's/[&/\]/\\&/g')|gI")"
    else
      # exact lower-case token
      newbase="${base//${search}/${replace}}"
    fi

    if [[ "$newbase" != "$base" ]]; then
      # Avoid collisions: if target exists, add a suffix
      local target="$dir/$newbase"
      if [[ -e "$target" && "$target" != "$path" ]]; then
        target="${target}.renamed"
      fi
      mv -n -- "$path" "$target"
    fi
  done
}

main() {
  need_root
  check_args "$@"

  DEVICE="$1"
  EFI_PART="$2"
  ROOT_PART="$3"
  FLAKE_URL="$4"
  CONFIG_NAME="$5"
  USER_NAME="$6"

  # Sanity checks on block devices
  for path in "$DEVICE" "$EFI_PART" "$ROOT_PART"; do
    if [[ ! -b "$path" ]]; then
      echo "Block device not found: $path" >&2
      exit 1
    fi
  done

  case "$DEVICE" in /dev/nvme*) devprefix="${DEVICE}p" ;; *) devprefix="$DEVICE" ;; esac
  if [[ "${EFI_PART}" != ${devprefix}* || "${ROOT_PART}" != ${devprefix}* ]]; then
    echo "Warning: ${EFI_PART} or ${ROOT_PART} may not belong to ${DEVICE}." >&2
  fi

  echo "==> Plan"
  echo "    Device:         $DEVICE"
  echo "    EFI partition:  $EFI_PART  (FAT32)"
  echo "    Root partition: $ROOT_PART (ext4)"
  echo "    Flake URL:      $FLAKE_URL"
  echo "    Config name:    $CONFIG_NAME"
  echo "    Replace token:  ${REPLACE_TOKEN}"
  echo "    New username:   ${USER_NAME}"
  echo "    Case-insensitive renames: ${CASE_INSENSITIVE_RENAME}"
  echo

  confirm_or_die

  # Quick network hint (non-fatal)
  if is_remote_github; then
    if ping -c1 -W2 github.com >/dev/null 2>&1; then
      echo "==> Network OK (github.com reachable)"
    else
      echo "!!  Warning: github.com not reachable. Ensure networking is up."
    fi
  fi

  echo "==> Unmounting anything under /mnt (best-effort)"
  umount -R /mnt 2>/dev/null || true

  echo "==> Wiping filesystem signatures"
  wipefs -af "$EFI_PART"
  wipefs -af "$ROOT_PART"

  echo "==> Formatting EFI as FAT32"
  mkfs.fat -F32 -n EFI "$EFI_PART"

  echo "==> Formatting ROOT as ext4"
  mkfs.ext4 -F -L nixos "$ROOT_PART"

  echo "==> Mounting ROOT at /mnt"
  mount "$ROOT_PART" /mnt

  echo "==> Mounting EFI at /mnt/boot"
  mkdir -p /mnt/boot
  mount "$EFI_PART" /mnt/boot

  # Prepare local working copy of the flake
  local_workdir="$(clone_flake_to_tmp)"
  echo "==> Local working dir: $local_workdir"

  # Enable flakes just for this process
  export NIX_CONFIG="experimental-features = nix-command flakes"

  # Perform replacements (contents first, then names to avoid racing paths)
  # Build a literal-safe search pattern for sed: since token is simple ("chase"),
  # we keep it literal. If you change REPLACE_TOKEN to include regex, escape it.
  SEARCH_PATTERN="$REPLACE_TOKEN"
  REPLACEMENT="$USER_NAME"

  replace_contents "$local_workdir" "$SEARCH_PATTERN" "$REPLACEMENT" "$CASE_INSENSITIVE_RENAME"
  rename_paths    "$local_workdir" "$SEARCH_PATTERN" "$REPLACEMENT" "$CASE_INSENSITIVE_RENAME"

  echo "==> Running nixos-install from modified flake"
  if [[ "$INSTALL_NO_ROOT_PASSWD" == "1" ]]; then
    nixos-install --flake "${local_workdir}#${CONFIG_NAME}" --no-root-passwd
  else
    nixos-install --flake "${local_workdir}#${CONFIG_NAME}"
  fi

  echo "==> Installation complete."
  echo "Next:"
  echo "  umount -R /mnt"
  echo "  reboot"
}

main "$@"
