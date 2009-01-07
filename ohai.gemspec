Gem::Specification.new do |s|
  s.name = %q{ohai}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Adam Jacob"]
  s.date = %q{2009-01-06}
  s.default_executable = %q{ohai}
  s.description = %q{I'm in yur server, findin yer dater}
  s.email = ["adam@opscode.com"]
  s.executables = ["ohai"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc"]
  s.files = [
    "History.txt", 
    "LICENSE", 
    "Manifest.txt", 
    "NOTICE", 
    "PostInstall.txt", 
    "README.rdoc", 
    "Rakefile", 
    "bin/ohai", 
    "extras/facter.rb",  
    "lib/ohai.rb", 
    "lib/ohai/config.rb", 
    "lib/ohai/exception.rb", 
    "lib/ohai/log.rb", 
    "lib/ohai/log/formatter.rb", 
    "lib/ohai/mixin/command.rb", 
    "lib/ohai/mixin/from_file.rb", 
    "lib/ohai/plugins/darwin/hostname.rb", 
    "lib/ohai/plugins/darwin/kernel.rb", 
    "lib/ohai/plugins/darwin/platform.rb", 
    "lib/ohai/plugins/hostname.rb", 
    "lib/ohai/plugins/kernel.rb", 
    "lib/ohai/plugins/linux/block_device.rb", 
    "lib/ohai/plugins/linux/cpu.rb", 
    "lib/ohai/plugins/linux/filesystem.rb", 
    "lib/ohai/plugins/linux/hostname.rb", 
    "lib/ohai/plugins/linux/kernel.rb", 
    "lib/ohai/plugins/linux/lsb.rb", 
    "lib/ohai/plugins/linux/memory.rb", 
    "lib/ohai/plugins/linux/network.rb", 
    "lib/ohai/plugins/linux/platform.rb", 
    "lib/ohai/plugins/linux/uptime.rb", 
    "lib/ohai/plugins/network.rb", 
    "lib/ohai/plugins/ohai_time.rb", 
    "lib/ohai/plugins/os.rb", 
    "lib/ohai/plugins/platform.rb", 
    "lib/ohai/plugins/ruby.rb", 
    "lib/ohai/plugins/uptime.rb", 
    "lib/ohai/system.rb", 
    "script/console", 
    "script/destroy", 
    "script/generate", 
    "tasks/rspec.rake",
    "features/development.feature", 
    "features/ohai.feature", 
    "features/steps/common.rb", 
    "features/steps/env.rb",
    "spec/ohai/log/log_formatter_spec.rb", 
    "spec/ohai/log_spec.rb", 
    "spec/ohai/mixin/from_file_spec.rb", 
    "spec/ohai/plugins/darwin/hostname_spec.rb", 
    "spec/ohai/plugins/darwin/kernel_spec.rb", 
    "spec/ohai/plugins/darwin/platform_spec.rb", 
    "spec/ohai/plugins/hostname_spec.rb", 
    "spec/ohai/plugins/kernel_spec.rb", 
    "spec/ohai/plugins/linux/cpu_spec.rb", 
    "spec/ohai/plugins/linux/hostname_spec.rb", 
    "spec/ohai/plugins/linux/kernel_spec.rb", 
    "spec/ohai/plugins/linux/lsb_spec.rb", 
    "spec/ohai/plugins/linux/platform_spec.rb", 
    "spec/ohai/plugins/linux/uptime_spec.rb", 
    "spec/ohai/plugins/ohai_time_spec.rb", 
    "spec/ohai/plugins/os_spec.rb", 
    "spec/ohai/plugins/platform_spec.rb", 
    "spec/ohai/plugins/ruby_spec.rb", 
    "spec/ohai/system_spec.rb", 
    "spec/ohai_spec.rb", 
    "spec/rcov.opts", 
    "spec/spec.opts", 
    "spec/spec_helper.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://www.opscode.com/ohai}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{I'm in yur server, findin yer dater}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_development_dependency(%q<newgem>, [">= 1.1.0"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<newgem>, [">= 1.1.0"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<newgem>, [">= 1.1.0"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
