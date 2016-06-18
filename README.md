# package-libvips-darwin

Uses Travis CI to generate a binary tarball
of libvips and its dependencies for use with
[sharp](https://github.com/lovell/sharp) on OS X.

Builds dylib files via homebrew
then modifies their depedency paths to be
the relative `@rpath` using `install_name_tool`.

The resulting file is transferred to S3 by setting
[various environment variables](https://docs.travis-ci.com/user/uploading-artifacts/).
