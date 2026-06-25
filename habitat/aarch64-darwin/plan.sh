export HAB_BLDR_CHANNEL="base-2025"
export HAB_REFRESH_CHANNEL="base-2025"
ruby_pkg="core/ruby3_4"
pkg_name="ohai"
pkg_origin="chef"
pkg_maintainer="The Chef Maintainers <humans@chef.io>"
pkg_description="The Chef Ohai"
pkg_license=('Apache-2.0')
pkg_bin_dirs=(bin)
pkg_build_deps=(
  core/git
  core/clang
  core/make
)
pkg_deps=(${ruby_pkg} core/coreutils core/libarchive)

pkg_svc_user=root

pkg_version() {
  cat "$SRC_PATH/VERSION"
}

do_before() {
  update_pkg_version
}

do_unpack() {
  mkdir -pv "$HAB_CACHE_SRC_PATH/$pkg_dirname"
  cp -RT "$PLAN_CONTEXT"/../.. "$HAB_CACHE_SRC_PATH/$pkg_dirname/"
}

do_setup_environment() {
  push_runtime_env GEM_PATH "${pkg_prefix}/vendor"
  set_runtime_env APPBUNDLER_ALLOW_RVM "true" # prevent appbundler from clearing out the carefully constructed runtime GEM_PATH
  set_runtime_env LANG "en_US.UTF-8"
  set_runtime_env LC_CTYPE "en_US.UTF-8"
}

do_prepare() {
  build_line "Setting up build environment for native extensions"
  export PATH="$(pkg_path_for core/make)/bin:$(pkg_path_for core/clang)/bin:$PATH"
  export CC="$(pkg_path_for core/clang)/bin/clang"
  export CXX="$(pkg_path_for core/clang)/bin/clang++"

  if [[ ! -f /usr/bin/env ]]; then
    ln -s "$(pkg_interpreter_for core/coreutils bin/env)" /usr/bin/env
  fi
}

do_build() {
  cd "$HAB_CACHE_SRC_PATH/$pkg_dirname" || exit_with "unable to cd to source directory" 1

  export GEM_HOME="$pkg_prefix/vendor"
  export HOME="$HAB_CACHE_SRC_PATH/$pkg_dirname"
  export GEM_SPEC_CACHE="$HAB_CACHE_SRC_PATH/$pkg_dirname/.gem/specs"
  mkdir -p "$GEM_SPEC_CACHE"
  export PATH="$(pkg_path_for core/make)/bin:$(pkg_path_for core/clang)/bin:$PATH"
  export CC="$(pkg_path_for core/clang)/bin/clang"
  export CXX="$(pkg_path_for core/clang)/bin/clang++"

  build_line "Setting GEM_PATH=$GEM_HOME"
  export GEM_PATH="$GEM_HOME"
  bundle config --local without integration deploy maintenance development debug
  bundle config --local jobs 4
  bundle config --local retry 5
  bundle config --local silence_root_warning 1
  bundle install
  ruby ./cleanup_lint_roller.rb
  ruby ./post-bundle-install.rb
  gem build ohai.gemspec
}

do_install() {
  cd "$HAB_CACHE_SRC_PATH/$pkg_dirname" || exit_with "unable to cd to source directory" 1

  # Copy NOTICE to the package directory
  if [[ -f "NOTICE" ]]; then
    build_line "Copying NOTICE to package directory"
    cp "NOTICE" "$pkg_prefix/"
  else
    build_line "Warning: NOTICE not found in source directory"
  fi

  export GEM_HOME="$pkg_prefix/vendor"
  export HOME="$HAB_CACHE_SRC_PATH/$pkg_dirname"
  export GEM_SPEC_CACHE="$HAB_CACHE_SRC_PATH/$pkg_dirname/.gem/specs"
  mkdir -p "$GEM_SPEC_CACHE"

  build_line "Setting GEM_PATH=$GEM_HOME"
  export GEM_PATH="$GEM_HOME"
  gem install ohai-*.gem --no-document

  build_line "** fixing binstub shebangs"
  fix_interpreter "${pkg_prefix}/vendor/bin/*" "$ruby_pkg" bin/ruby

  build_line "** generating binstubs for ohai with precise version pins"
  "${pkg_prefix}/vendor/bin/appbundler" . "$pkg_prefix/bin" ohai

  build_line "** patching binstubs to allow running directly"
  for binstub in ${pkg_prefix}/bin/*; do
    sed -i -e "/require ['\"]rubygems['\"]/r ${PLAN_CONTEXT}/../../binstub_patch.rb" "$binstub"
  done

  if ! grep -q 'APPBUNDLER_ALLOW_RVM' "${pkg_prefix}/bin/ohai"; then
    build_line "ERROR: binstub patch injection failed for ${pkg_prefix}/bin/ohai"
    return 1
  fi

  build_line "** creating wrapper for runtime environment"
  mkdir -p "$pkg_prefix/libexec"
  mv "$pkg_prefix/bin/ohai" "$pkg_prefix/libexec/ohai"
  cat <<EOF > "$pkg_prefix/bin/ohai"
#!/bin/bash
set -e

export PATH="$(pkg_path_for ${ruby_pkg})/bin:/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:$pkg_prefix/vendor/bin:\$PATH"
export DYLD_LIBRARY_PATH="$(pkg_path_for core/libarchive)/lib:\$DYLD_LIBRARY_PATH"
export GEM_HOME="$pkg_prefix/vendor"
export GEM_PATH="$pkg_prefix/vendor"

exec $(pkg_path_for ${ruby_pkg})/bin/ruby $pkg_prefix/libexec/ohai "\$@"
EOF
  chmod -v 755 "$pkg_prefix/bin/ohai"

  rm -rf "$GEM_PATH/cache"
  rm -rf "$GEM_PATH/bundler"
  rm -rf "$GEM_PATH/doc"
}

do_after() {
  build_line "Removing .github directories from vendored gems..."
  find "$pkg_prefix/vendor/gems" -type d -name ".github" \
      | while read github_dir; do rm -rf "$github_dir"; done

  build_line "Removing stray Gemfile.lock files from vendored gems..."
  find "$pkg_prefix/vendor/gems" -name "Gemfile.lock" -type f -delete
}

do_strip() {
  return 0
}
