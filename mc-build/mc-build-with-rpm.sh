#! /bin/bash

# Build Midnight Commander on a system without development packages.
# Only RPM based distributions are supported.

set -eu

RPM_ROOT="$(pwd)/rpmroot"
MC_ARCH="x86_64"
MC_INSTALL_DIR="$HOME/.opt/mc"
RPMS=(glib2 glib2-devel ncurses-libs ncurses-devel pcre pcre-devel slang slang-devel)

if ! test -d "$RPM_ROOT"; then
    rm -f *.rpm
    dnf download "${RPMS[@]}"
    for pkg in *."$MC_ARCH".rpm; do
        rpm2cpio "$pkg" | cpio -i -d -D "$RPM_ROOT"
    done
fi

./configure --prefix="$MC_INSTALL_DIR" \
PKG_CONFIG_PATH=$RPM_ROOT/usr/lib64/pkgconfig \
CPPFLAGS="-I$RPM_ROOT/usr/lib64/glib-2.0/include -I$RPM_ROOT/usr/include/glib-2.0 -I$RPM_ROOT/usr/include" \
LDFLAGS="-L$RPM_ROOT/usr/lib64 -lpthread"

echo "Now you can run `make all install`"
