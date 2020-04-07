#! /bin/sh

# Download and build glib 2.x statically with all dependencies and then
# compile GNU Midnight Commander against it.
# Copyright (C) 2003 Pavel Roskin
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This script is incomplete!  It doesn't download libiconv.  This is OK
# for glibc-based systems, but probably not for others.  This limitation
# is known.  Please don't report it.


: ${MC_TOPDIR=`pwd`}
: ${TOP_SRCDIR=$MC_TOPDIR/__src}
: ${DESTDIR=$MC_TOPDIR/__inst}
: ${CACHEDIR=$MC_TOPDIR/__cache}
: ${GZIP=gzip}
: ${XZ=xz}

: ${GETTEXT_VERSION=0.19.5.1}
GETTEXT_URL="http://ftp.gnu.org/gnu/gettext/gettext-$GETTEXT_VERSION.tar.gz"

: ${LIBFFI_VERSION=3.2.1}
LIBFFI_URL="ftp://sourceware.org/pub/libffi/libffi-$LIBFFI_VERSION.tar.gz"

: ${GLIB_VERSION=2.44.1}
GLIB_VERSION_BASE=`echo $GLIB_VERSION | sed 's,\([^.]*\.[^.]*\).*,\1,'`
GLIB_URL="http://ftp.gnome.org/pub/gnome/sources/glib/$GLIB_VERSION_BASE/glib-$GLIB_VERSION.tar.xz"

: ${PKGCONFIG_VERSION=0.28}
PKGCONFIG_URL="http://pkgconfig.freedesktop.org/releases/pkg-config-$PKGCONFIG_VERSION.tar.gz"

# Report error to stderr and exit with code 1
error() {
  echo "$@" >&2
  exit 1
}

# Get file from the given URL, keep remote name
get_file() {
  curl --location --remote-name "$1" || \
  wget --passive-ftp "$1" || \
  wget "$1" || \
  exit 1
}

# Download file if needed, unpack it and go to the source directory
prepare_src() {
  cd "$CACHEDIR"
  URL=$1
  FILE=`echo "$URL" | sed 's,.*/,,'`
  case $FILE in
    *.gz) UNPACK=$GZIP;;
    *.xz) UNPACK=$XZ;;
    *) error "Unknown archive extension: $FILE"
  esac
  if $UNPACK -vt "$FILE" 2>/dev/null; then : ; else
    get_file "$URL" || exit 1
  fi
  cd "$TOP_SRCDIR"
  SRCDIR=`echo "$FILE" | sed 's,\.tar\.[^.]*,,'`
  rm -rf "$SRCDIR"
  $UNPACK -cd "$CACHEDIR/$FILE" | tar xf -
  cd "$SRCDIR" || error "Cannot find directory: $SRCDIR"
}

if test -f $MC_TOPDIR/src/filemanager/dir.c; then : ; else
  error "Not in the top-level directory of GNU Midnight Commander."
fi

if test -f $MC_TOPDIR/configure; then : ; else
  $MC_TOPDIR/autogen.sh --help >/dev/null || exit 1
fi

mkdir -p "$TOP_SRCDIR"
mkdir -p "$CACHEDIR"
rm -rf "$DESTDIR"

# Compile gettext
prepare_src "$GETTEXT_URL"
cd gettext-runtime
if test -f src/gettext.c; then : ; else
  error "gettext source is incomplete"
fi

./configure --disable-shared --prefix="$DESTDIR" || exit 1
make all || exit 1
make install || exit 1

# Compile libffi
prepare_src "$LIBFFI_URL"
if test -f src/closures.c; then : ; else
  error "libffi source is incomplete"
fi

./configure --disable-shared --prefix="$DESTDIR" || exit 1
make all || exit 1
make install || exit 1

# Compile glib
prepare_src "$GLIB_URL"
if test -f glib/glist.c; then : ; else
  error "glib source is incomplete"
fi

./configure --disable-shared --prefix="$DESTDIR" \
            CPPFLAGS="-I$DESTDIR/include" \
            LDFLAGS="-L$DESTDIR/lib" \
            LIBFFI_CFLAGS="-I$DESTDIR/lib/libffi-$LIBFFI_VERSION/include" \
            LIBFFI_LIBS="-L$DESTDIR/lib -L$DESTDIR/lib64 -lffi" \
            || exit 1
make all || exit 1
make install || exit 1

# Compile pkgconfig
prepare_src "$PKGCONFIG_URL"
if test -f pkg.c; then : ; else
  error "pkg-config source is incomplete"
fi

./configure --disable-shared \
            --prefix="$DESTDIR" \
            GLIB_CFLAGS="-I$DESTDIR/include/glib-2.0 -I$DESTDIR/lib/glib-2.0/include" \
            GLIB_LIBS="-L$DESTDIR/lib -L$DESTDIR/lib64 -lglib-2.0" \
            || exit 1
make all || exit 1
make install || exit 1

# Compile mc
cd "$MC_TOPDIR"
./configure --without-x \
            PKG_CONFIG="$DESTDIR/bin/pkg-config" \
            GLIB_CFLAGS="-I$DESTDIR/include/glib-2.0 -I$DESTDIR/lib/glib-2.0/include" \
            GLIB_LIBS="-L$DESTDIR/lib -L$DESTDIR/lib64 -lgmodule-2.0 -lglib-2.0" \
            GMODULE_CFLAGS="-I$DESTDIR/include/glib-2.0 -I$DESTDIR/lib/glib-2.0/include" \
            GMODULE_LIBS="-L$DESTDIR/lib -L$DESTDIR/lib64 -lgmodule-2.0 -lglib-2.0" \
            $@ || exit 1
make clean || exit 1
make || exit 1

echo "GNU Midnight Commander has been successfully compiled"
