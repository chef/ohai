def ruby_19?
  !!(RUBY_VERSION =~ /^1.9/)
end

def ruby_18?
  !!(RUBY_VERSION =~ /^1.8/)
end

def windows?
  !!(RUBY_PLATFORM =~ /mswin|mingw|windows/)
end

def windows_2008r2_or_later?
  return false unless windows?
  wmi = WmiLite::Wmi.new
  host = wmi.first_of('Win32_OperatingSystem')
  version = host['version']
  return false unless version
  components = version.split('.').map do | component |
    component.to_i
  end
  components.length >= 2 && components[0] >= 6 && components[1] >= 1
end

# def jruby?

def unix?
  !windows?
end

def os_x?
  !!(RUBY_PLATFORM =~ /darwin/)
end

def solaris?
  !!(RUBY_PLATFORM =~ /solaris/)
end

def freebsd?
  !!(RUBY_PLATFORM =~ /freebsd/)
end

DEV_NULL = windows? ? 'NUL' : '/dev/null'
