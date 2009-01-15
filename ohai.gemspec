Gem::Specification.new do |s|
  s.name = %q{ohai}
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Adam Jacob"]
  s.autorequire = %q{ohai}
  s.date = %q{2009-01-15}
  s.default_executable = %q{ohai}
  s.description = %q{Ohai profiles your system and emits JSON}
  s.email = %q{adam@opscode.com}
  s.executables = ["ohai"]
  s.files = ["LICENSE", "README.rdoc", "Rakefile", "extras/facter.rb", "lib/ohai", "lib/ohai/config.rb", "lib/ohai/exception.rb", "lib/ohai/log", "lib/ohai/log/formatter.rb", "lib/ohai/log.rb", "lib/ohai/mixin", "lib/ohai/mixin/command.rb", "lib/ohai/mixin/from_file.rb", "lib/ohai/plugins", "lib/ohai/plugins/command.rb", "lib/ohai/plugins/darwin", "lib/ohai/plugins/darwin/hostname.rb", "lib/ohai/plugins/darwin/kernel.rb", "lib/ohai/plugins/darwin/network.rb", "lib/ohai/plugins/darwin/platform.rb", "lib/ohai/plugins/darwin/ps.rb", "lib/ohai/plugins/darwin/ssh_host_key.rb", "lib/ohai/plugins/hostname.rb", "lib/ohai/plugins/kernel.rb", "lib/ohai/plugins/keys.rb", "lib/ohai/plugins/languages.rb", "lib/ohai/plugins/linux", "lib/ohai/plugins/linux/block_device.rb", "lib/ohai/plugins/linux/cpu.rb", "lib/ohai/plugins/linux/filesystem.rb", "lib/ohai/plugins/linux/hostname.rb", "lib/ohai/plugins/linux/kernel.rb", "lib/ohai/plugins/linux/lsb.rb", "lib/ohai/plugins/linux/memory.rb", "lib/ohai/plugins/linux/network.rb", "lib/ohai/plugins/linux/platform.rb", "lib/ohai/plugins/linux/ps.rb", "lib/ohai/plugins/linux/ssh_host_key.rb", "lib/ohai/plugins/linux/uptime.rb", "lib/ohai/plugins/network.rb", "lib/ohai/plugins/ohai_time.rb", "lib/ohai/plugins/os.rb", "lib/ohai/plugins/platform.rb", "lib/ohai/plugins/ruby.rb", "lib/ohai/plugins/uptime.rb", "lib/ohai/system.rb", "lib/ohai.rb", "spec/ohai", "spec/ohai/log", "spec/ohai/log/log_formatter_spec.rb", "spec/ohai/log_spec.rb", "spec/ohai/mixin", "spec/ohai/mixin/from_file_spec.rb", "spec/ohai/plugins", "spec/ohai/plugins/darwin", "spec/ohai/plugins/darwin/hostname_spec.rb", "spec/ohai/plugins/darwin/kernel_spec.rb", "spec/ohai/plugins/darwin/platform_spec.rb", "spec/ohai/plugins/hostname_spec.rb", "spec/ohai/plugins/kernel_spec.rb", "spec/ohai/plugins/linux", "spec/ohai/plugins/linux/cpu_spec.rb", "spec/ohai/plugins/linux/hostname_spec.rb", "spec/ohai/plugins/linux/kernel_spec.rb", "spec/ohai/plugins/linux/lsb_spec.rb", "spec/ohai/plugins/linux/platform_spec.rb", "spec/ohai/plugins/linux/uptime_spec.rb", "spec/ohai/plugins/ohai_time_spec.rb", "spec/ohai/plugins/os_spec.rb", "spec/ohai/plugins/platform_spec.rb", "spec/ohai/plugins/ruby_spec.rb", "spec/ohai/system_spec.rb", "spec/ohai_spec.rb", "spec/rcov.opts", "spec/spec.opts", "spec/spec_helper.rb", "bin/ohai"]
  s.has_rdoc = true
  s.homepage = %q{http://wiki.opscode.com/display/ohai}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Ohai profiles your system and emits JSON}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<json>, [">= 0"])
    else
      s.add_dependency(%q<json>, [">= 0"])
    end
  else
    s.add_dependency(%q<json>, [">= 0"])
  end
end
