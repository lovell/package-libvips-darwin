#!/bin/sh

# Clean working directories
rm -rf lib include
mkdir lib include

# Use pkg-config to automagically find and copy necessary header files
for path in $(pkg-config --cflags --static vips-cpp libcroco-0.6 | tr ' ' '\n' | grep '^-I' | cut -c 3- | sort | uniq); do
  cp -R ${path}/ include;
done;
rm include/vips/vipsc++.h

# Manually copy JPEG and GIF header files
cp /usr/local/opt/jpeg/include/*.h include
cp /usr/local/opt/giflib/include/*.h include

# Use pkg-config to automagically find and copy necessary dylib files
for path in $(pkg-config --libs --static vips-cpp libcroco-0.6 | tr ' ' '\n' | grep '^-L' | cut -c 3- | sort | uniq); do
  find ${path} -type f -name *.dylib | xargs -I {} cp {} lib;
done;
rm -f lib/libvipsCC.*.dylib

# Manually copy JPEG and GIF dylib files
cp /usr/local/opt/jpeg/lib/libjpeg.8.dylib lib
cp /usr/local/opt/giflib/lib/libgif.4.dylib lib

# Modify all dylib file dependencies to use relative paths
cd lib
for filename in *.dylib; do
  chmod 644 $filename;
  install_name_tool -id @rpath/$filename $filename
  for dependency in $(otool -L $filename | cut -d' ' -f1 | grep '/usr/local'); do
    install_name_tool -change $dependency @rpath/$(basename $dependency) $filename;
  done;
done;
cd ..

# Generate versions.json
printf "{\n\
  \"cairo\": \"$(pkg-config --modversion cairo)\",\n\
  \"croco\": \"$(pkg-config --modversion libcroco-0.6)\",\n\
  \"exif\": \"$(pkg-config --modversion libexif)\",\n\
  \"fontconfig\": \"$(pkg-config --modversion fontconfig)\",\n\
  \"freetype\": \"$(pkg-config --modversion freetype2)\",\n\
  \"gdkpixbuf\": \"$(pkg-config --modversion gdk-pixbuf-2.0)\",\n\
  \"gif\": \"$(grep GIFLIB_ include/gif_lib.h | cut -d' ' -f3 | paste -s -d'.' -)\",\n\
  \"glib\": \"$(pkg-config --modversion glib-2.0)\",\n\
  \"gsf\": \"$(pkg-config --modversion libgsf-1)\",\n\
  \"harfbuzz\": \"$(pkg-config --modversion harfbuzz)\",\n\
  \"jpeg\": \"$(/usr/local/opt/jpeg/bin/jpegtran -version 2>&1 | cut -d' ' -f3)\",\n\
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
}" >lib/versions.json

# Generate tarball
GZIP=-9 tar cfz libvips-$(pkg-config --modversion vips-cpp)-dar.tar.gz include lib

# Remove working directories
rm -rf lib include

# Display checksum
shasum *.tar.gz
