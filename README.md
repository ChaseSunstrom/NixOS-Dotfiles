---

# README.md

# NixOS Dotfiles

Declarative NixOS config with a bootstrap installer. The installer can:
- **format & mount** your target partitions (EFI + root),
- **fetch the flake** from GitHub (or use a local path),
- **rename all `chase` occurrences** in file/dir **names** *and* **file contents** to your user name,
- **install NixOS** using the flake’s host configuration.

> Default token to replace is **`chase`**. You can change the token via `REPLACE_TOKEN`.

---

## Repo layout (typical)

- `flake.nix` — top-level flake
- `hosts/` — per-machine NixOS configs (use one as `<CONFIG_NAME>`)
- `home/` — Home Manager configs (optional)
- `modules/`, `overlays/` — reusable modules & overlays
- `install.sh` — the bootstrap script in this README

---

## Fresh install (minimal ISO)

1. **Boot the NixOS minimal ISO** and get online.

2. **Partition the disk** (UEFI example):
   - **p1**: EFI System Partition (~512 MB, FAT32)
   - **p2**: root (ext4, rest of disk)

3. **One-liner install** *(formats p1/p2, fetches & personalizes repo, installs)*:

```bash
curl -fsSL https://raw.githubusercontent.com/ChaseSunstrom/NixOS-Dotfiles/main/install.sh | \
  sudo bash -s -- /dev/nvme0n1 /dev/nvme0n1p1 /dev/nvme0n1p2 \
  github:ChaseSunstrom/NixOS-Dotfiles <CONFIG_NAME> <YOUR_USERNAME>
````

* Replace the device/partitions appropriately.
* `<CONFIG_NAME>` is a host defined in `hosts/` (e.g., `my-hostname`).
* `<YOUR_USERNAME>` replaces **all** `chase` tokens in names & contents.

If you prefer to save first:

```bash
curl -fsSL https://raw.githubusercontent.com/ChaseSunstrom/NixOS-Dotfiles/main/install.sh -o install.sh
chmod +x install.sh
sudo ./install.sh /dev/nvme0n1 /dev/nvme0n1p1 /dev/nvme0n1p2 \
  github:ChaseSunstrom/NixOS-Dotfiles <CONFIG_NAME> <YOUR_USERNAME>
```

4. **Reboot** once the installer finishes:

```bash
umount -R /mnt
reboot
```

---

## Flags & environment variables

* `NONINTERACTIVE=1` — skip the destructive confirmation prompt (useful for CI/one-liners)
* `INSTALL_NO_ROOT_PASSWD=1` — pass `--no-root-passwd` to `nixos-install` (use if your flake defines users/passwords)
* `CASE_INSENSITIVE_RENAME=1` — match/replace `chase`, `Chase`, `CHASE`, etc.
* `REPLACE_TOKEN=chase` — change the token that gets replaced in names & contents
* `EXCLUDE_DIRS=".git .direnv node_modules result vendor .cache"` — directories excluded from renaming & content edits

Examples:

```bash
NONINTERACTIVE=1 CASE_INSENSITIVE_RENAME=1 \
curl -fsSL https://raw.githubusercontent.com/ChaseSunstrom/NixOS-Dotfiles/main/install.sh | \
sudo bash -s -- /dev/nvme0n1 /dev/nvme0n1p1 /dev/nvme0n1p2 \
github:ChaseSunstrom/NixOS-Dotfiles <CONFIG_NAME> <YOUR_USERNAME>
```

```bash
INSTALL_NO_ROOT_PASSWD=1 REPLACE_TOKEN=chase \
sudo ./install.sh /dev/nvme0n1 /dev/nvme0n1p1 /dev/nvme0n1p2 \
. <CONFIG_NAME> <YOUR_USERNAME>
```

> Using `.` as the `<FLAKE_URL>` tells the script to use the current directory (if you already cloned the repo locally).

---

## Using the flake after install

Make changes in the repo and then:

```bash
sudo nixos-rebuild switch --flake .#<CONFIG_NAME>
```

(You can also point to the GitHub URL: `--flake github:ChaseSunstrom/NixOS-Dotfiles#<CONFIG_NAME>`.)

If you use Home Manager outputs (optional):

```bash
home-manager switch --flake .#<user>@<host>
```

---

## Notes / Caveats

* **Scope of replacement:** The installer replaces **both** names *and* contents of files for every occurrence of `REPLACE_TOKEN` (default `chase`). This is convenient but can be broad. If your repo contains unrelated text with the token (e.g., comments, docs, code), those will change too.

  * To narrow scope, adjust `EXCLUDE_DIRS` or change `REPLACE_TOKEN`.
* **Backups:** The installer operates on a **temporary clone** (for remote flakes) or a **copied** directory (for local flakes), so your origin repo remains untouched.
* **File types:** The content replacement runs over regular files. It skips excluded directories. If you need to avoid certain extensions (e.g., images), we can add an extension allowlist.
* **Firmware:** Script detects UEFI presence. The default layout assumes UEFI (EFI partition is mounted at `/boot`). Legacy is okay too (no extra steps here).

---

## Troubleshooting

* **GitHub unreachable:** Bring networking up (`nmtui`, `nmcli`, `wpa_supplicant`) and retry.
* **Host not found:** Ensure `<CONFIG_NAME>` exists in your `flake.nix` under `nixosConfigurations`.
* **Permission prompts:** Use `INSTALL_NO_ROOT_PASSWD=1` if your flake manages users/passwords declaratively.

---

## License

See repository for license. Contributions welcome!
