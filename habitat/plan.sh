pkg_name=ohai
pkg_origin=chef
ruby_pkg="core/ruby31"
pkg_deps=(${ruby_pkg} core/coreutils)
pkg_build_deps=(
    core/make
    core/sed
    core/gcc
    )
pkg_bin_dirs=(bin)
do_setup_environment() {
  build_line 'Setting GEM_HOME="$pkg_prefix/lib"'
  export GEM_HOME="$pkg_prefix/lib"

  build_line "Setting GEM_PATH=$GEM_HOME"
  export GEM_PATH="$GEM_HOME"
}

pkg_version() {
  cat "$SRC_PATH/VERSION"
}
do_before() {
  update_pkg_version
}
do_unpack() {
  mkdir -pv "$HAB_CACHE_SRC_PATH/$pkg_dirname"
  cp -RT "$PLAN_CONTEXT"/.. "$HAB_CACHE_SRC_PATH/$pkg_dirname/"
}
do_build() {
    pushd "$HAB_CACHE_SRC_PATH/$pkg_dirname/"
        gem build ohai.gemspec
    popd
}
do_install() {
    pushd "$HAB_CACHE_SRC_PATH/$pkg_dirname/"
        gem install ohai-*.gem --no-document
    popd
    wrap_ruby_bin
}
wrap_ruby_bin() {
  local bin="$pkg_prefix/bin/$pkg_name"
  local real_bin="$GEM_HOME/gems/ohai-${pkg_version}/bin/ohai"
  build_line "Adding wrapper $bin to $real_bin"
  cat <<EOF > "$bin"
#!$(pkg_path_for core/bash)/bin/bash
set -e

# Set binary path that allows ohai to use non-Hab pkg binaries
export PATH="/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:\$PATH"

# Set Ruby paths defined from 'do_setup_environment()'
export GEM_HOME="$GEM_HOME"
export GEM_PATH="$GEM_PATH"

exec $(pkg_path_for core/ruby31)/bin/ruby $real_bin \$@
EOF
  chmod -v 755 "$bin"
}


do_strip() {
  return 0
}