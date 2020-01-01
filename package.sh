#!/bin/sh

# Clean working directories
rm -rf lib include
mkdir lib include

# Use pkg-config to automagically find and copy necessary header files
for path in $(pkg-config --cflags --static vips-cpp libcroco-0.6 | tr ' ' '\n' | grep '^-I' | cut -c 3- | sort | uniq); do
  cp -R ${path}/ include;
done;
rm include/gettext-po.h

# Manually copy header files for giflib
cp $(brew --prefix giflib)/include/*.h include

# Pack only the relevant shared libraries
# and modify all dylib file dependencies to use relative paths
function copydeps {
  local file=$1
  local dest_dir=$2

  local base=$(basename $file)

  for dep in $(otool -LX $file | awk '{print $1}' | grep '/usr/local'); do
    base_dep=$(basename $dep)

    echo "$base depends on $base_dep"
    cp -Ln $dep $dest_dir/$base_dep
    chmod 644 $dest_dir/$base_dep

    install_name_tool -id @rpath/$base_dep $dest_dir/$base_dep

    if [ $base != $base_dep ]; then
      install_name_tool -change $dep @rpath/$base_dep $dest_dir/$base

      # Call this function (recursive) on each dependency of this library
      copydeps $dest_dir/$base_dep $dest_dir
    fi
  done;
}

copydeps $(brew --prefix vips)/lib/libvips-cpp.42.dylib lib

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
  \"jpeg\": \"$(pkg-config --modversion libjpeg)\",\n\
  \"lcms\": \"$(pkg-config --modversion lcms2)\",\n\
  \"orc\": \"$(pkg-config --modversion orc-0.4)\",\n\
  \"pango\": \"$(pkg-config --modversion pango)\",\n\
  \"pixman\": \"$(pkg-config --modversion pixman-1)\",\n\
  \"png\": \"$(pkg-config --modversion libpng)\",\n\
  \"svg\": \"$(pkg-config --modversion librsvg-2.0)\",\n\
  \"tiff\": \"$(pkg-config --modversion libtiff-4)\",\n\
  \"vips\": \"$(pkg-config --modversion vips-cpp)-rc3\",\n\
  \"webp\": \"$(pkg-config --modversion libwebp)\",\n\
  \"xml\": \"$(pkg-config --modversion libxml-2.0)\"\n\
}" >versions.json

printf "\"darwin-x64\"" >platform.json

# Generate tarball
TARBALL=libvips-$(pkg-config --modversion vips-cpp)-rc3-darwin-x64.tar.gz
tar cfz "${TARBALL}" include lib *.json
advdef --recompress --shrink-insane "${TARBALL}"

# Remove working directories
rm -rf lib include *.json

# Display checksum
shasum *.tar.gz
