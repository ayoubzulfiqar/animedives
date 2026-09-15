#!/bin/bash
set -euo pipefail

PROJECT_ROOT="/home/sensei/Projects/flutter/animedives"
VERSION="1.6.9"
ARCH="amd64"
BUILD_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
PKG_ROOT="$PROJECT_ROOT/build/packages"
DEB_DIR="$PKG_ROOT/deb/animedives_${VERSION}_${ARCH}"
RPM_DIR="$PKG_ROOT/rpm"
ARCH_DIR="$PKG_ROOT/arch"

rm -rf "$PKG_ROOT"
mkdir -p "$PKG_ROOT"

# ── Common directory structure ──
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/lib/animedives"
mkdir -p "$DEB_DIR/usr/bin"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$DEB_DIR/usr/share/icons/hicolor/256x256/apps"

cp "$BUILD_DIR/animedives" "$DEB_DIR/usr/lib/animedives/animedives"
cp -r "$BUILD_DIR/data" "$DEB_DIR/usr/lib/animedives/data"
cp -r "$BUILD_DIR/lib" "$DEB_DIR/usr/lib/animedives/lib"

# Strip rpath from shared libraries (RPM rejects non-standard rpaths like
# /home/sensei/Android/Sdk/jre/lib/server)
# Strip only bad absolute rpaths from .so files (keep $ORIGIN/lib on the binary)
find "$DEB_DIR/usr/lib/animedives/lib" -name "*.so" -exec patchelf --remove-rpath {} \; 2>/dev/null || true

cat > "$DEB_DIR/usr/bin/animedives" << 'WRAPPER'
#!/bin/sh
exec /usr/lib/animedives/animedives "$@"
WRAPPER
chmod +x "$DEB_DIR/usr/bin/animedives"

cp "$PROJECT_ROOT/linux/animedives.desktop" "$DEB_DIR/usr/share/applications/animedives.desktop"
cp "$PROJECT_ROOT/assets/animedives.png" "$DEB_DIR/usr/share/icons/hicolor/256x256/apps/animedives.png"

# ── DEBIAN control ──
cat > "$DEB_DIR/DEBIAN/control" << EOF
Package: animedives
Version: ${VERSION}
Section: games
Priority: optional
Architecture: ${ARCH}
Maintainer: Ayoub Zulfiqar <contact@ayoubzulfiqar.com>
Description: An anime watching app with ad-shielded WebView
 Animedives wraps anime streaming sites in an ad-shielded, full-screen
 capable WebView with smart history tracking and anti-bot bypass.
Homepage: https://ayoubzulfiqar.com
EOF

cat > "$DEB_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/sh
chmod +x /usr/bin/animedives
EOF
chmod +x "$DEB_DIR/DEBIAN/postinst"

# Build .deb
dpkg-deb --build --root-owner-group "$DEB_DIR" \
  "$PKG_ROOT/animedives_${VERSION}_${ARCH}.deb"
echo "BUILD  .deb  -> $PKG_ROOT/animedives_${VERSION}_${ARCH}.deb"

# ── RPM ──
mkdir -p "$RPM_DIR/SPECS" "$RPM_DIR/BUILD" "$RPM_DIR/RPMS" "$RPM_DIR/SRPMS" "$RPM_DIR/SOURCES" "$RPM_DIR/src"

cat > "$RPM_DIR/SPECS/animedives.spec" << 'SPECEOF'
%global debug_package %{nil}
Name: animedives
Version: 1.6.9
Release: 1%{?dist}
Summary: An anime watching app with ad-shielded WebView
License: MIT
BuildArch: x86_64
Source0: %{name}-%{version}.tar.gz
%description
Animedives wraps anime streaming sites in an ad-shielded, full-screen
capable WebView with smart history tracking and anti-bot bypass.
Homepage: https://ayoubzulfiqar.com
%prep
%setup -q
%build
%install
mkdir -p %{buildroot}/usr/lib/animedives
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/icons/hicolor/256x256/apps
cp -r animedives %{buildroot}/usr/lib/animedives/
cp -r data %{buildroot}/usr/lib/animedives/
cp -r lib %{buildroot}/usr/lib/animedives/
cat > %{buildroot}/usr/bin/animedives << 'WRAPPER'
#!/bin/sh
exec /usr/lib/animedives/animedives "$@"
WRAPPER
chmod +x %{buildroot}/usr/bin/animedives
cp animedives.desktop %{buildroot}/usr/share/applications/
cp animedives.png %{buildroot}/usr/share/icons/hicolor/256x256/apps/
%files
/usr/bin/animedives
/usr/lib/animedives/
/usr/share/applications/animedives.desktop
/usr/share/icons/hicolor/256x256/apps/animedives.png
%changelog
* Sat Sep 14 2026 Ayoub Zulfiqar <contact@ayoubzulfiqar.com> - 1.6.9-1
- Initial release
SPECEOF

mkdir -p "$RPM_DIR/src/animedives-1.6.9"
cp "$DEB_DIR/usr/lib/animedives/animedives" "$RPM_DIR/src/animedives-1.6.9/"
cp -r "$DEB_DIR/usr/lib/animedives/data" "$RPM_DIR/src/animedives-1.6.9/"
cp -r "$DEB_DIR/usr/lib/animedives/lib" "$RPM_DIR/src/animedives-1.6.9/"
cp "$PROJECT_ROOT/linux/animedives.desktop" "$RPM_DIR/src/animedives-1.6.9/"
cp "$PROJECT_ROOT/assets/animedives.png" "$RPM_DIR/src/animedives-1.6.9/"
tar -czf "$RPM_DIR/SOURCES/animedives-1.6.9.tar.gz" -C "$RPM_DIR/src" animedives-1.6.9

rpmbuild -ba \
  --define "_topdir $RPM_DIR" \
  --define "_tmppath /tmp/rpm-tmp" \
  "$RPM_DIR/SPECS/animedives.spec" 2>&1 | tail -10 || true

RPM_FILE=$(find "$RPM_DIR/RPMS" -name "animedives-*.rpm" 2>/dev/null | head -1)
if [ -n "$RPM_FILE" ]; then
  cp "$RPM_FILE" "$PKG_ROOT/$(basename $RPM_FILE)"
  echo "BUILD  .rpm  -> $PKG_ROOT/$(basename $RPM_FILE)"
else
  echo "WARN   .rpm  -> rpmbuild failed, creating source archive instead"
  tar -czf "$PKG_ROOT/animedives_${VERSION}_${ARCH}.rpm.src.tar.gz" -C "$DEB_DIR" .
fi

# ── Arch Linux package (.tar.zst) ──
mkdir -p "$ARCH_DIR/usr/lib/animedives"
mkdir -p "$ARCH_DIR/usr/bin"
mkdir -p "$ARCH_DIR/usr/share/applications"
mkdir -p "$ARCH_DIR/usr/share/icons/hicolor/256x256/apps"

cp "$BUILD_DIR/animedives" "$ARCH_DIR/usr/lib/animedives/"
cp -r "$BUILD_DIR/data" "$ARCH_DIR/usr/lib/animedives/"
cp -r "$BUILD_DIR/lib" "$ARCH_DIR/usr/lib/animedives/"
cp "$PROJECT_ROOT/linux/animedives.desktop" "$ARCH_DIR/usr/share/applications/"
cp "$PROJECT_ROOT/assets/animedives.png" "$ARCH_DIR/usr/share/icons/hicolor/256x256/apps/"

cat > "$ARCH_DIR/usr/bin/animedives" << 'WRAPPER'
#!/bin/sh
exec /usr/lib/animedives/animedives "$@"
WRAPPER
chmod +x "$ARCH_DIR/usr/bin/animedives"

cat > "$ARCH_DIR/PKGBUILD" << 'PKGEOF'
# Maintainer: Ayoub Zulfiqar <contact@ayoubzulfiqar.com>
pkgname=animedives
pkgver=1.6.9
pkgrel=1
pkgdesc="An anime watching app with ad-shielded WebView"
arch=('x86_64')
url="https://ayoubzulfiqar.com"
license=('MIT')
depends=('gtk3' 'libsecret' 'json-glib' 'libnotify' 'libcurl')
package() {
  cd "$srcdir"
  mkdir -p "$pkgdir/usr/lib/animedives"
  cp -r usr/lib/animedives/* "$pkgdir/usr/lib/animedives/"
  install -Dm755 usr/bin/animedives "$pkgdir/usr/bin/animedives"
  install -Dm644 usr/share/applications/animedives.desktop "$pkgdir/usr/share/applications/animedives.desktop"
  install -Dm644 usr/share/icons/hicolor/256x256/apps/animedives.png "$pkgdir/usr/share/icons/hicolor/256x256/apps/animedives.png"
}
PKGEOF

tar -I zstd -cf "$PKG_ROOT/animedives_${VERSION}-${ARCH}.pkg.tar.zst" -C "$ARCH_DIR" usr PKGBUILD
echo "BUILD  .zst  -> $PKG_ROOT/animedives_${VERSION}-${ARCH}.pkg.tar.zst"

echo ""
echo "=== Package summary ==="
ls -lh "$PKG_ROOT"/*.deb "$PKG_ROOT"/*.rpm "$PKG_ROOT"/*.tar.zst 2>/dev/null || \
  ls -lh "$PKG_ROOT"/*.deb "$PKG_ROOT"/*.tar.gz "$PKG_ROOT"/*.tar.zst 2>/dev/null