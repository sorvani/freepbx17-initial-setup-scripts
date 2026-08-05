# FreePBX 17 Initial Setup Scripts

Bootstrap and maintenance scripts for a FreePBX 17 (Debian) host: create an SSH
user with their public keys installed, strip the commercial modules you are not
licensing once FreePBX is in, and patch the OS and modules from then on.

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

`apt upgrade` is deliberate rather than `full-upgrade`: it will never remove an
installed package to resolve a dependency. Packages it cannot upgrade under that
rule are reported as *kept back*, which is a prompt for a human rather than
something to resolve unattended on a PBX.

> [!NOTE]
> If `apt update` reports
> `E: Repository 'http://ftp.debian.org/debian stable InRelease' changed its
> 'Codename' value from 'bookworm' to 'trixie'`, that is the FreePBX 17
> installer's doing, not this script. It writes
> `/etc/apt/sources.list.d/archive_uri-http_ftp_debian_org_debian-bookworm.list`
> pinned to the `stable` suite rather than to `bookworm`, so the entry rolled
> over when Debian 13 released. Fix it by changing `stable` to `bookworm` in
> that file.
>
> Do **not** clear it with `apt update --allow-releaseinfo-change`. That accepts
> the rollover and starts pulling Debian 13 packages onto a bookworm host whose
> FreePBX repo is bookworm-only. Do not delete the file either — it is the only
> source providing the `non-free` component.

## 4. Adding users later

Also placed in your home directory by `root_setup.sh`:

```bash
sudo ./add_debian_user.sh
```

The user half of `root_setup.sh` on its own, with the same key source options.

It gives the new user `update.sh` and `add_debian_user.sh` in their own home
directory too. Anyone with console access to a FreePBX box is an administrator
regardless, so there is nothing gained by making them hunt for the scripts.
`post_install_cleanup.sh` is not copied — that one is a single pass right after
the FreePBX install and is not useful to a user added later.

## Refreshing the scripts on an existing host

The scripts are copied into a home directory **once**, when that account is
created. Nothing updates them afterwards, so a host built months ago is still
running whatever version it was given — including any bug since fixed here.

To pull current copies onto an existing host:

```bash
cd ~
for s in post_install_cleanup.sh update.sh add_debian_user.sh; do
  wget -qO $s https://raw.githubusercontent.com/sorvani/freepbx17-initial-setup-scripts/main/$s
  chmod +x $s
done
```

Worth doing before you trust `update.sh` on a host you have not touched in a
while.

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
