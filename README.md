# nixos-configs

Personal NixOS configurations for a laptop, Raspberry Pi server, WSL, and a
Home Assistant kiosk tablet. [flake.nix](flake.nix) defines the hosts and their
module imports; [flake.lock](flake.lock) pins their dependencies.

## Hosts

| Flake configuration | Architecture | Purpose | Configuration |
| --- | --- | --- | --- |
| `msi-thin-gf63-12vf` | `x86_64-linux` | Plasma 6 laptop and build machine | [Host module](hosts/msi-thin-gf63-12vf/msi-thin-gf63-12vf.nix) |
| `rpi3` | `aarch64-linux` | Raspberry Pi service host; network hostname `nixosrpi3` | [Host module](hosts/rpi3/rpi3.nix) |
| `wsl` | `x86_64-linux` | NixOS-WSL development environment | [Host module](hosts/wsl.nix) |
| `switch10e` | `x86_64-linux` | Acer Aspire Switch 10 E Home Assistant kiosk | [Host module](hosts/switch10e/switch10e.nix) |
| `switch10e-iso` | `x86_64-linux` | Live installer for the tablet's 32-bit UEFI firmware | [Installer module](hosts/switch10e/iso.nix) |

### MSI laptop

The MSI Thin GF63 12VF runs Plasma 6 with automatic login, NetworkManager,
German keyboard layout, and the Europe/Berlin timezone. Intel graphics render
by default; the NVIDIA RTX 4060 is available through PRIME offload
(`nvidia-offload <command>`).

Its disk configuration uses systemd-boot and LUKS-encrypted Btrfs, with separate
subvolumes for the root filesystem, home directories, Nix store, snapshots, and
an 8 GB swapfile. The layout describes an existing SSD with a BitLocker data
partition; disk paths and partition boundaries are specific to this machine.

[modules/profiles/desktop.nix](modules/profiles/desktop.nix) adds Zsh, Firefox
ESR, desktop applications, selected tools from the unstable package set, and
AArch64 emulation for building Raspberry Pi packages.

### Raspberry Pi server

The `rpi3` configuration runs a minimal system with extlinux boot, an ext4 root
filesystem, zram, a watchdog, and SSH with password authentication disabled.
Weekly garbage collection removes generations older than seven days, alongside
weekly store optimisation.

The flake currently enables these service modules:

| Service | Configuration |
| --- | --- |
| Miniflux RSS reader, nginx, and ACME certificate setup | [miniflux.nix](modules/services/miniflux.nix) |
| i2pd I2P router | [i2pd.nix](modules/services/i2pd.nix) |
| Vaultwarden password manager | [vaultwarden.nix](modules/services/vaultwarden.nix) |
| Pruned Bitcoin Core node | [bitcoind.nix](modules/services/bitcoind.nix) |
| Home Assistant, integrations, and dashboards | [home-assistant.nix](modules/services/home-assistant.nix) |

Miniflux, Vaultwarden, and Home Assistant are served through nginx with TLS.
Certificates use Cloudflare DNS validation; Home Assistant also has an IP
allowlist in its virtual host configuration. Home Assistant's configuration is
split into `home-assistant-home.nix`, `home-assistant-private.nix`,
`home-assistant-solar.nix`, and the files in
[modules/services/dashboards/](modules/services/dashboards/).

[hosts/rpi3/wireguard.nix](hosts/rpi3/wireguard.nix) configures the `wg0` tunnel.
It uses `table = "off"`, so its peer's `allowedIPs` does not automatically
install a default route.

AdGuard Home, Unbound, and qBittorrent imports are commented out in the flake.
A Paperless module also exists but is not imported by a current host.

### WSL

The WSL configuration uses NixOS-WSL with `tom` as the default user, Windows
driver support and interoperability, Docker, and AArch64 emulation. It also
includes the agenix command-line tool.

## Repository layout

- `hosts/`: machine-specific configuration, hardware settings, disk layouts,
  and the tablet installer.
- `modules/common.nix`: shared `tom` user, SSH authorized keys, flakes support,
  Neovim as the default editor, and common packages.
- `modules/profiles/`: reusable desktop configuration.
- `modules/services/`: service configuration and Home Assistant dashboards.
- `secrets/`: encrypted agenix files, recipient rules, and public SSH keys.
- `.github/workflows/check.yml`: flake validation on pushes to `main` and pull
  requests.

## Building and deploying

Run commands from the repository root. Use a configuration name from the host
table, which may differ from the machine's network hostname.

Build a host without activating it:

```sh
nix build .#nixosConfigurations.msi-thin-gf63-12vf.config.system.build.toplevel
```

Apply the laptop configuration locally:

```sh
sudo nixos-rebuild switch --flake .#msi-thin-gf63-12vf
```

For WSL, use `.#wsl` instead. To build on the MSI and deploy to the Raspberry Pi:

```sh
nixos-rebuild switch --flake .#rpi3 \
  --target-host tom@nixosrpi3 --use-remote-sudo
```

The MSI desktop profile enables AArch64 emulation for the Pi build. Remote
deployment requires SSH access, working hostname resolution or an IP address,
and sudo access on the target.

Build the Switch 10 E installer image with:

```sh
nix build .#nixosConfigurations.switch10e-iso.config.system.build.isoImage
```

The installer uses IA32 GRUB to boot the tablet's 64-bit system through its
32-bit UEFI firmware. The installed host also uses IA32 GRUB and identifies the
eMMC by hardware ID because its `/dev/mmcblk*` numbering can change. Installation
notes are in the tablet's host, installer, and disk configuration files.

## Switch 10 E kiosk

The Acer Aspire Switch 10 E (SW3-013) runs a lightweight XFCE desktop with
LightDM automatically logging in as `tom`. Firefox ESR opens the Home Assistant
dashboard in kiosk mode when the XFCE session starts.

The configuration lives in [hosts/switch10e/switch10e.nix](hosts/switch10e/switch10e.nix).
Its session setup script:

- Disables idle suspend, lid-close actions, and automatic backlight dimming on
  both AC power and battery.
- Disables DPMS and X11 screen blanking; the XFCE screensaver is also disabled.
- Adds a battery indicator before the top panel's clock, preserving existing
  panel items and avoiding duplicate indicators. The indicator shows the battery
  percentage.

Logind also ignores lid-close events, idle actions, and suspend/hibernate keys.
These settings keep the kiosk awake; they do not disable explicit suspend
requests from other applications or the desktop menu.

### Deploying changes

Build and deploy from the MSI rather than on the tablet:

```sh
nixos-rebuild switch --flake .#switch10e \
  --target-host tom@switch10e --use-remote-sudo
```

Log out and back in, or reboot, after deployment to run the session setup and
Firefox autostart entries. A rebuild alone does not rerun them in an existing
desktop session. The power settings are reapplied at each XFCE login.

To change the dashboard URL, edit the `Exec` line in the
`switch10e-firefox.desktop` entry in the host configuration.

### XFCE power-setting values

The pinned XFCE Power Manager 4.20 uses `0` for never suspending in
`inactivity-on-ac` and `inactivity-on-battery`. A value of `14` means a
14-minute timeout in this version. For `brightness-on-ac` and
`brightness-on-battery`, `9` is the special value that disables idle dimming.
DPMS and X11 screen blanking are separate controls, so the session script also
sets `dpms-enabled` to `false` and runs `xset s off`.

## Secrets and SSH keys

Secrets are stored as encrypted `.age` files in [secrets/](secrets/).
[secrets/agenix-rules.nix](secrets/agenix-rules.nix) defines their recipients
using public keys from `secrets/ssh/users/` and `secrets/ssh/hosts/`. Modules
declare `age.secrets` and pass the resulting decrypted paths to services.

To edit a secret on a machine with the agenix CLI and an authorized private key:

```sh
cd secrets
agenix -e miniflux.age
```

After changing recipient rules, re-encrypt the files with an existing authorized
identity:

```sh
cd secrets
agenix --rekey
```

The CLI discovers `agenix-rules.nix` in the `secrets` directory. Use
`-i /path/to/private-key` if the required identity is not found automatically.

The MSI uses `/root/.ssh/host_ed25519_key` as its agenix identity. Other hosts
using secrets need a private identity matching a recipient in the rules.

The shared user configuration automatically authorizes every `.pub` file in
`secrets/ssh/users/` for `tom` on every host. Agenix recipients are maintained
separately in `agenix-rules.nix`; adding a login key does not automatically grant
access to encrypted secrets. Stage new key and module files with `git add` so
Git-backed flake evaluation can see them.

## Formatting, validation, and dependency updates

Format the repository using the flake's `nixfmt-tree` formatter:

```sh
nix fmt
```

Run the same flake check used by CI:

```sh
nix flake check --all-systems --keep-going
```

For a focused configuration evaluation without a full system build:

```sh
nix eval --raw .#nixosConfigurations.switch10e.config.system.build.toplevel.drvPath
```

The primary package set follows `nixos-26.05`. `pkgsUnstable` comes from a
separately locked `nixpkgs-unstable-small` input, also used for the tablet's
`linuxPackages_testing` kernel until 7.4 is stable. Update it with
`nix flake update nixpkgs-unstable-small` and check the resolved kernel version
before deploying the tablet.

Update one dependency deliberately, for example the primary package set:

```sh
nix flake update nixpkgs
```

Use `nix flake update` to update all inputs within their configured references.
Review the lock-file diff, validate, and build affected hosts before deployment.
Build outputs named `result*` are ignored by Git.
