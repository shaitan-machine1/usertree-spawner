pkgbase=usertree-spawner
pkgname=('usertree-spawner' 'usertree-spawner-backend-s6' 'usertree-spawner-s6')
pkgver=0.1.0
pkgrel=2
pkgdesc='Elogind-specific per-user service-manager launcher and lifecycle supervisor'
arch=('x86_64')
url='https://github.com/shaitan-machine1/usertree-spawner'
license=('GPL-3.0-only')
makedepends=('cargo')
options=('!debug')
source=("$pkgbase-$pkgver.tar.gz::$url/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=('SKIP')

build() {
    cd "$pkgbase-$pkgver"
    cargo build --release --locked --workspace
}

check() {
    cd "$pkgbase-$pkgver"
    cargo test --locked --workspace
}

package_usertree-spawner() {
    depends=('elogind' 'gcc-libs' 'glibc' 'pam')
    optdepends=('usertree-spawner-backend-s6: per-user s6-svscan and s6-rc backend')
    backup=('etc/usertree-spawner/config.toml'
            'etc/pam.d/usertree-spawner-manager')

    cd "$pkgbase-$pkgver"
    install -Dm755 target/release/usertree-spawnerd \
        "$pkgdir/usr/bin/usertree-spawnerd"
    install -Dm755 target/release/usertree-spawner-supervisor \
        "$pkgdir/usr/libexec/usertree-spawner-supervisor"
    install -Dm755 target/release/libpam_usertree_spawner.so \
        "$pkgdir/usr/lib/security/pam_usertree_spawner.so"

    install -Dm644 config/config.toml \
        "$pkgdir/etc/usertree-spawner/config.toml"
    install -dm755 "$pkgdir/etc/usertree-spawner/backends"
    install -Dm644 pam.d/usertree-spawner-manager \
        "$pkgdir/etc/pam.d/usertree-spawner-manager"

    install -Dm644 README.md \
        "$pkgdir/usr/share/doc/usertree-spawner/README.md"
    install -Dm644 pam.d/login-stack-example \
        "$pkgdir/usr/share/doc/usertree-spawner/login-stack-example"
    for document in docs/*.md; do
        install -Dm644 "$document" \
            "$pkgdir/usr/share/doc/usertree-spawner/${document##*/}"
    done
    install -Dm644 LICENSE \
        "$pkgdir/usr/share/licenses/usertree-spawner/LICENSE"
}

package_usertree-spawner-backend-s6() {
    pkgdesc='s6-svscan and s6-rc backend for usertree-spawner'
    depends=('usertree-spawner' 's6-user')

    cd "$pkgbase-$pkgver"
    install -Dm755 backends/s6 \
        "$pkgdir/usr/libexec/usertree-spawner/backends/s6"
    install -Dm644 LICENSE \
        "$pkgdir/usr/share/licenses/usertree-spawner-backend-s6/LICENSE"
}

package_usertree-spawner-s6() {
    pkgdesc='s6-rc system service definition for usertree-spawner'
    groups=('s6-world')
    depends=('elogind' 'usertree-spawner' 'usertree-spawner-backend-s6' 's6-base')
    provides=('init-usertree-spawner')
    conflicts=('init-usertree-spawner')

    cd "$pkgbase-$pkgver"
    install -Dm644 integration/s6-rc/usertree-spawnerd/type \
        "$pkgdir/etc/s6/sv/usertree-spawnerd/type"
    install -Dm755 integration/s6-rc/usertree-spawnerd/run \
        "$pkgdir/etc/s6/sv/usertree-spawnerd/run"
    install -Dm644 integration/s6-rc/usertree-spawnerd/dependencies.d/elogind \
        "$pkgdir/etc/s6/sv/usertree-spawnerd/dependencies.d/elogind"
    install -Dm644 LICENSE \
        "$pkgdir/usr/share/licenses/usertree-spawner-s6/LICENSE"
}
