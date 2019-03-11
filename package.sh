#!/bin/sh

# Clean working directories
rm -rf lib include
mkdir lib include

# Use pkg-config to automagically find and copy necessary header files
for path in $(pkg-config --cflags --static vips-cpp libcroco-0.6 | tr ' ' '\n' | grep '^-I' | cut -c 3- | sort | uniq); do
  cp -R ${path}/ include;
done;
rm include/gettext-po.h

# Manually copy header files for jpeg and giflib
cp /usr/local/opt/jpeg/include/*.h include
cp /usr/local/opt/giflib/include/*.h include

# Use pkg-config to automagically find and copy necessary dylib files
for path in $(pkg-config --libs --static vips-cpp libcroco-0.6 | tr ' ' '\n' | grep '^-L' | cut -c 3- | sort | uniq); do
  if [ -d ${path} ]; then
    find ${path} \( -type l -o -type f \) -name *.dylib | xargs -I {} cp -a {} lib;
  fi
done;

# Manually copy dylib files for jpeg and giflib
cp /usr/local/opt/jpeg/lib/libjpeg.9.dylib lib
cp /usr/local/opt/giflib/lib/libgif.7.dylib lib

# Remove unused libraries
cd lib
rm -f *gettext* libasprintf* libcairo-gobject* libcairo-script-interpreter* \
  libharfbuzz-gobject* libharfbuzz-icu* libharfbuzz-subset* \
  liborc-test* libpcre16* libpcre32* libpcrecpp* libpcreposix* libtiffxx*

# Modify all dylib file dependencies to use relative paths
for filename in *.dylib; do
  chmod 644 $filename;
  install_name_tool -id @rpath/$filename $filename
  for dependency in $(otool -L $filename | cut -d' ' -f1 | grep '/usr/local'); do
    install_name_tool -change $dependency @rpath/$(basename $dependency) $filename;
  done;
done;
cd ..

# Fix file permissions
chmod 644 include/*.h
chmod 644 lib/*.dylib

# Generate versions.json
printf "{\n\
  \"cairo\": \"$(pkg-config --modversion cairo)\",\n\
  \"croco\": \"$(pkg-config --modversion libcroco-0.6)\",\n\
  \"exif\": \"$(pkg-config --modversion libexif)\",\n\
  \"fontconfig\": \"$(pkg-config --modversion fontconfig)\",\n\
  \"freetype\": \"$(pkg-config --modversion freetype2)\",\n\
  \"fribidi\": \"$(pkg-config --modversion fribidi)\",\n\
  \"gdkpixbuf\": \"$(pkg-config --modversion gdk-pixbuf-2.0)\",\n\
  \"gif\": \"$(grep GIFLIB_ include/gif_lib.h | cut -d' ' -f3 | paste -s -d'.' -)\",\n\
  \"glib\": \"$(pkg-config --modversion glib-2.0)\",\n\
  \"gsf\": \"$(pkg-config --modversion libgsf-1)\",\n\
  \"harfbuzz\": \"$(pkg-config --modversion harfbuzz)\",\n\
  \"jpeg\": \"$(grep JPEG_LIB_VERSION_ include/jpeglib.h | cut -d' ' -f4 | paste -s -d'.' -)\",\n\
  \"lcms\": \"$(pkg-config --modversion lcms2)\",\n\
  \"orc\": \"$(pkg-config --modversion orc-0.4)\",\n\
  \"pango\": \"$(pkg-config --modversion pango)\",\n\
  \"pixman\": \"$(pkg-config --modversion pixman-1)\",\n\
  \"png\": \"$(pkg-config --modversion libpng)\",\n\
  \"svg\": \"$(pkg-config --modversion librsvg-2.0)\",\n\
  \"tiff\": \"$(pkg-config --modversion libtiff-4)\",\n\
  \"vips\": \"$(pkg-config --modversion vips-cpp)\",\n\
  \"webp\": \"$(pkg-config --modversion libwebp)\",\n\
  \"xml\": \"$(pkg-config --modversion libxml-2.0)\"\n\
}" >versions.json

printf "\"darwin-x64\"" >platform.json

# Generate tarball
TARBALL=libvips-$(pkg-config --modversion vips-cpp)-darwin-x64.tar.gz
tar cfz "${TARBALL}" include lib *.json
advdef --recompress --shrink-insane "${TARBALL}"

# Remove working directories
rm -rf lib include *.json

# Display checksum
shasum *.tar.gz
