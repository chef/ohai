# x86-mingw32 Gemspec #
gemspec = eval(IO.read(File.expand_path("../ohai.gemspec", __FILE__)))

gemspec.platform = "x86-mingw32"

gemspec.add_dependency "ffi", "1.5.0"

gemspec
