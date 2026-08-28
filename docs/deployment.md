# Deployment

`usertree-spawner` changes the login path. Test it on a disposable Artix machine
with an independent root console. The implementation is Linux-specific and
uses pidfds, `SO_PEERCRED`, `SOCK_SEQPACKET`, parent-death signals, and
`openat2` where available.

## Package order

Install `s6-user-projects` first. Then install these packages together:

```text
usertree-spawner
usertree-spawner-backend-s6-user
usertree-spawner-s6
```

The system integration package depends only on `usertree-spawner` and `s6-base`.
It deliberately does not force a per-user backend. The core package already
carries the elogind package dependency; the s6-rc source separately contains
its service dependency on `elogind`.

## Install GitHub Release packages

Download package files and `SHA256SUMS` from the official
[GitHub Releases page](https://github.com/shaitan-machine1/usertree-spawner/releases/latest):

```sh
sha256sum -c SHA256SUMS
sudo pacman -U ./*.pkg.tar.zst
```

Packages are currently unsigned and should only be obtained from the official
repository release page.

## Build from source

Install `base-devel`, `git`, and Rust/Cargo first:

```sh
git clone https://github.com/shaitan-machine1/usertree-spawner.git
cd usertree-spawner
./build.sh --clean && sudo pacman -U ./packages/*.pkg.tar.zst
```

The script uses `makepkg --nodeps`, never invokes pacman, and writes
`packages/SHA256SUMS`. Direct non-package builds remain available:

```sh
make test
make
```

Important installed paths are:

```text
/usr/bin/usertree-spawnerd
/usr/bin/usertree-spawner-pam
/usr/libexec/usertree-spawner-supervisor
/usr/lib/security/pam_usertree_spawner.so
/usr/libexec/usertree-spawner/backends/s6-user
/etc/usertree-spawner/config.toml
/etc/pam.d/usertree-spawner-manager
/etc/s6/sv/usertree-spawnerd
```

## Select a backend explicitly

The installed configuration intentionally has no backend assignment. The
daemon refuses to start until the administrator edits
`/etc/usertree-spawner/config.toml` and supplies a valid backend name:

```toml
backend = "s6-user"
```

Names must match `[a-z0-9][a-z0-9._-]*` and resolve beneath the fixed trusted
backend directory `/usr/libexec/usertree-spawner/backends`. Absolute paths,
slashes, traversal, uppercase characters, and leading dots are rejected.

## Internal PAM lease

`/etc/pam.d/usertree-spawner-manager` must contain required `pam_elogind` and
must never include `pam_usertree_spawner` recursively:

```pam
session required pam_elogind.so class=background type=unspecified
```

The helper verifies the returned UID, runtime path, service, class, and type
against login1 before starting a backend. Manager classes are not used because
they do not pin the elogind user.

## Start the system daemon

The system graph is:

```text
elogind -> usertree-spawnerd -> PAM login
```

The packaged s6-rc source supplies the first edge:

```sh
sudo s6 enable usertree-spawnerd
sudo s6 apply
sudo s6 live status usertree-spawnerd
```

Do not activate usersv in PAM until the daemon is confirmed running. On
shutdown the daemon waits for helpers/managers before elogind is stopped.

## Activate the common Artix PAM stack

Artix SDDM, local, and remote login stacks include
`/etc/pam.d/system-login`. Activate the module with the packaged editor:

```sh
sudo usertree-spawner-pam enable
usertree-spawner-pam status
```

It atomically inserts exactly one line after `pam_elogind.so`:

```pam
session required pam_usertree_spawner.so
```

The utility is root-only for changes, idempotent, preserves file metadata, and
fails closed on unsafe or unexpected layouts. To deactivate:

```sh
sudo usertree-spawner-pam disable
```

Package removal attempts the same disable operation before deleting the PAM
module. The project does not edit Artix's optional pambase-owned
`pam_turnstile.so` entry.

The PAM client timeout defaults to 35 seconds. It must remain greater than
`login_readiness_timeout_seconds`. A bounded override is supported:

```pam
session required pam_usertree_spawner.so timeout=60
```

## s6-user backend

The `s6-user` backend:

- receives only the sanitized user environment and verified runtime path;
- obtains runtime and persistent paths from `s6-user paths export`;
- never constructs or creates `/run/user/$UID`;
- initializes/synchronizes the private repository;
- preserves existing service prescriptions;
- execs the actual `s6-svscan` manager;
- releases PAM after shallow manager readiness;
- terminates an asynchronous boot transaction if the manager disappears;
- requests dependency-aware stop before signaling `s6-svscan`.

Runtime directories are selected by `s6 --user` from `XDG_RUNTIME_DIR`.
Persistent repository, boot database, and store paths are configured by
s6-user.

## Target-system tests

Run the portable suite first:

```sh
make test
```

Then run live login1 tests on Artix:

```sh
make test-live
```

Finally verify SDDM, TTY, SSH, concurrent sessions, manager crash/restart,
last logout, PAM disable/enable, and `loginctl terminate-user`. The full
checklist is in the s6-user project documentation.

## Rollback

From the root console:

```sh
sudo usertree-spawner-pam disable
sudo s6 disable usertree-spawnerd
sudo s6 apply
```

Only after PAM has been disabled should the module/core package be removed.
Forced user termination or manual runtime-directory deletion cannot guarantee
normal backend shutdown ordering.
