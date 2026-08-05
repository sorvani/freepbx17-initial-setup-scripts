# FreePBX 17 Initial Setup Scripts

Bootstrap scripts for a fresh FreePBX 17 (Debian) host: create an SSH user with
their public keys installed, then strip the commercial modules you are not
licensing after FreePBX is installed.

FreePBX 17 moved to Debian, so these replace
[`InitialSetup/`](https://github.com/sorvani/freepbx-helper-scripts/tree/master/InitialSetup)
from [sorvani/freepbx-helper-scripts](https://github.com/sorvani/freepbx-helper-scripts),
which targets FreePBX 15/16 on Sangoma OS (CentOS).

| Script | Run as | When |
| --- | --- | --- |
| `root_setup.sh` | root | On a bare Debian install, **before** installing FreePBX |
| `post_install_cleanup.sh` | root | **After** the FreePBX 17 install completes |
| `update.sh` | root | Ongoing, whenever you want to patch the OS and modules |
| `add_debian_user.sh` | root | Any time you need another SSH user |

## 1. Before installing FreePBX

Log in to the new Debian install as root:

```bash
wget https://raw.githubusercontent.com/sorvani/freepbx17-initial-setup-scripts/main/root_setup.sh
chmod +x root_setup.sh
./root_setup.sh
```

It asks for a Linux username and where to get that user's SSH public keys (see
[SSH key sources](#ssh-key-sources) below), then creates the account with sudo
and writes the keys to `authorized_keys`.

The password is set to `ChangeMe` and **expired immediately**, so the first SSH
login forces a change. Log back in as the new user before continuing with the
FreePBX 17 install.

It also drops `post_install_cleanup.sh`, `update.sh`, and `add_debian_user.sh`
into the new user's home directory, executable and owned by them, so the other
scripts are already on the box when you need them. If you cloned this repo
rather than downloading `root_setup.sh` on its own, the local copies are used;
otherwise they are fetched from `main`.

## 2. After installing FreePBX

`root_setup.sh` already put this in your home directory:

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

## 3. Keeping it updated

```bash
sudo ./update.sh
```

Runs `apt update`/`upgrade`/`autoremove`, then `fwconsole ma upgradeall`,
`fwconsole chown`, and a reload. Logs to `upgrade-YYYYmmdd-HHMMSS.log` in the
current directory, lists any modules it upgraded, and reminds you to schedule a
reboot if the box has been up more than 30 days.

Both the OS and the module stages can take a long time if you have not updated
in a while.

## 4. Adding users later

Also placed in your home directory by `root_setup.sh`:

```bash
sudo ./add_debian_user.sh
```

The user half of `root_setup.sh` on its own, with the same key source options.

## SSH key sources

Both `root_setup.sh` and `add_debian_user.sh` prompt for the new user's public
keys. Whatever you type is matched against three cases, in this order:

### 1. A single public key, pasted

Anything starting with `ssh-`, `ecdsa-`, or `sk-` is treated as one literal key
and written to `authorized_keys` unchanged. Use this when the person's keys are
not published anywhere — they paste the contents of their `~/.ssh/id_ed25519.pub`
and you are done.

```
Enter the github username, URL, or public key for jared: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleKeyDataHere jared@laptop
```

The `sk-` prefix covers FIDO/hardware-backed keys (`sk-ssh-ed25519@openssh.com`).

> [!NOTE]
> This branch takes **one** key, because the prompt reads a single line. If you
> need several, use a URL or run `add_debian_user.sh` again.

### 2. A URL

Anything starting with `http://` or `https://` is fetched as-is and appended.
The response is expected to already be in `authorized_keys` format — one key per
line. Useful for a team key list you host yourself.

```
Enter the github username, URL, or public key for jared: https://keys.example.com/jared.keys
```

### 3. A GitHub username

Anything else is treated as a GitHub username and expanded to
`https://github.com/<username>.keys`. That is a public, unauthenticated endpoint
GitHub has served for years — it returns the account's SSH **authentication**
keys, one per line, already in the right format.

```
Enter the github username, URL, or public key for jared: sorvani
```

> [!WARNING]
> A GitHub account with **no SSH keys uploaded**, and an **organization** name
> rather than a personal one, both return HTTP 200 with an empty body. Nothing
> is added to `authorized_keys` and the script does not warn you. Only a
> username that does not exist at all returns 404.
>
> Check the account has keys first — open `https://github.com/<username>.keys`
> in a browser. People who clone over HTTPS with a token, or use GitHub Desktop,
> often have none.

GitHub strips the trailing comment from keys it serves, so imported keys carry
no `user@host` label. To keep the file readable later, both scripts write a
provenance line above each import:

```
# imported from https://github.com/sorvani.keys on 2026-08-04
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQTopHmbABzHvsb7BFenrl...
```

`sshd` ignores lines beginning with `#`, so these are purely for whoever reads
the file a year or two from now.

## License

GPL-3.0, same as
[sorvani/freepbx-helper-scripts](https://github.com/sorvani/freepbx-helper-scripts).
