PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin
LIBEXECDIR ?= $(PREFIX)/libexec
PAMDIR ?= $(PREFIX)/lib/security
SYSCONFDIR ?= /etc
DESTDIR ?=

.PHONY: all test install install-s6 clean

all:
	cargo build --release --locked --workspace

test:
	cargo test --locked --workspace
	cargo clippy --locked --workspace --all-targets -- -D warnings
	sh -n backends/s6 tests/backends/backend-test

install: all
	install -Dm755 target/release/usertree-spawnerd \
		$(DESTDIR)$(BINDIR)/usertree-spawnerd
	install -Dm755 target/release/usertree-spawner-supervisor \
		$(DESTDIR)$(LIBEXECDIR)/usertree-spawner-supervisor
	install -Dm755 target/release/libpam_usertree_spawner.so \
		$(DESTDIR)$(PAMDIR)/pam_usertree_spawner.so
	install -Dm755 backends/s6 \
		$(DESTDIR)$(LIBEXECDIR)/usertree-spawner/backends/s6
	install -Dm644 config/config.toml \
		$(DESTDIR)$(SYSCONFDIR)/usertree-spawner/config.toml
	install -dm755 $(DESTDIR)$(SYSCONFDIR)/usertree-spawner/backends
	install -Dm644 pam.d/usertree-spawner-manager \
		$(DESTDIR)$(SYSCONFDIR)/pam.d/usertree-spawner-manager
	install -Dm644 docs/backend-protocol-v1.md \
		$(DESTDIR)$(PREFIX)/share/doc/usertree-spawner/backend-protocol-v1.md
	install -Dm644 docs/deployment.md \
		$(DESTDIR)$(PREFIX)/share/doc/usertree-spawner/deployment.md
	install -Dm644 docs/security.md \
		$(DESTDIR)$(PREFIX)/share/doc/usertree-spawner/security.md
	install -Dm644 docs/wire-protocols-v1.md \
		$(DESTDIR)$(PREFIX)/share/doc/usertree-spawner/wire-protocols-v1.md
	install -Dm644 README.md \
		$(DESTDIR)$(PREFIX)/share/doc/usertree-spawner/README.md
	install -Dm644 LICENSE \
		$(DESTDIR)$(PREFIX)/share/licenses/usertree-spawner/LICENSE

# Install this source into the distribution's s6-rc source store. The exact
# store location is distribution policy, so it is intentionally configurable.
S6_RC_SOURCE_DIR ?= /etc/s6/sv
install-s6:
	mkdir -p $(DESTDIR)$(S6_RC_SOURCE_DIR)
	cp -a integration/s6-rc/usertree-spawnerd \
		$(DESTDIR)$(S6_RC_SOURCE_DIR)/usertree-spawnerd

clean:
	cargo clean
