# FreePBX 17 Initial Setup Scripts

Bootstrap scripts for a fresh FreePBX 17 (Debian) host: create an SSH user with
keys pulled from GitHub, then strip the commercial modules you are not
licensing after FreePBX is installed.

FreePBX 17 moved to Debian, so these replace
[`InitialSetup/`](https://github.com/sorvani/freepbx-helper-scripts/tree/master/InitialSetup)
from [sorvani/freepbx-helper-scripts](https://github.com/sorvani/freepbx-helper-scripts),
which targets FreePBX 15/16 on Sangoma OS (CentOS).

| Script | Run as | When |
| --- | --- | --- |
| `root_setup.sh` | root | On a bare Debian install, **before** installing FreePBX |
| `post_install_cleanup.sh` | root | **After** the FreePBX 17 install completes |
| `add_debian_user.sh` | root | Any time you need another SSH user |

## 1. Before installing FreePBX

Log in to the new Debian install as root:

```bash
wget https://raw.githubusercontent.com/sorvani/freepbx17-initial-setup-scripts/main/root_setup.sh
chmod +x root_setup.sh
./root_setup.sh
```

It asks for a Linux username and a GitHub username, then creates the account
with sudo, installs [ssh-key-sync](https://github.com/shoenig/ssh-key-sync), and
pulls that GitHub account's public keys into `authorized_keys`.

The password is set to `ChangeMe` and **expired immediately**, so the first SSH
login forces a change. Log back in as the new user before continuing with the
FreePBX 17 install.

## 2. After installing FreePBX

```bash
sudo ./post_install_cleanup.sh
```

Installs `git` and `glances`, removes the commercial modules (keeping
`sysadmin`), re-enables the commercial repo, fixes permissions with
`fwconsole chown`, and reloads. Reboot afterwards, then finish setup in the web
UI.

> [!WARNING]
> This deletes every commercial module except `sysadmin` — including
> `sangomaconnect`, `queuestats`, `faxpro`, `pms` and the rest. Read the
> `fwconsole ma delete` list before running it if you license any of them.

## 3. Adding users later

```bash
sudo ./add_debian_user.sh
```

The user half of `root_setup.sh` on its own, for a host where `ssh-key-sync` is
already installed.

## License

GPL-3.0, same as
[sorvani/freepbx-helper-scripts](https://github.com/sorvani/freepbx-helper-scripts).
