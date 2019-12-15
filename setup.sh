#!/bin/sh
set -e

HOMEBREW_NO_AUTO_UPDATE=1
HOMEBREW_NO_INSTALL_CLEANUP=1
KEEP_PACKAGES="cmake gdbm gettext giflib git jpeg libffi libpng libxml2 openssl openssl@1.1 pcre pkg-config python readline sqlite xz"
PKG_CONFIG_PATH="/usr/local/opt/libffi/lib/pkgconfig:/usr/local/opt/jpeg-turbo/lib/pkgconfig:$PKG_CONFIG_PATH"

brew cleanup
brew list -1 | grep -Ev ${KEEP_PACKAGES// /|} | xargs brew rm -f
brew update
brew upgrade

brew install advancecomp
brew tap lovell/package-libvips-darwin https://github.com/lovell/package-libvips-darwin.git
brew install lovell/package-libvips-darwin/libtiff --build-bottle
brew install lovell/package-libvips-darwin/gdk-pixbuf --build-bottle
brew postinstall lovell/package-libvips-darwin/gdk-pixbuf
brew install lovell/package-libvips-darwin/vips --build-bottle
