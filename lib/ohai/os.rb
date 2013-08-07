#
#
#

require 'rbconfig'

module Ohai
  module OS

    def self.collect_os
      case ::RbConfig::CONFIG['host_os']
      when /aix(.+)$/
        return "aix"
      when /darwin(.+)$/
        return "darwin"
      when /hpux(.+)$/
        return "hpux"
      when /linux/
        return "linux"
      when /freebsd(.+)$/
        return "freebsd"
      when /openbsd(.+)$/
        return "openbsd"
      when /netbsd(.*)$/
        return "netbsd"
      when /solaris2/
        return "solaris2"
      when /mswin|mingw32|windows/
        # After long discussion in IRC the "powers that be" have come to a concensus
        # that there is no other Windows platforms exist that were not based on the
        # Windows_NT kernel, so we herby decree that "windows" will refer to all
        # platforms built upon the Windows_NT kernel and have access to win32 or win64
        # subsystems.
        return "windows"
      else
        return ::RbConfig::CONFIG['host_os']
      end
    end
    
    def collect_os
      case ::RbConfig::CONFIG['host_os']
      when /aix(.+)$/
        return "aix"
      when /darwin(.+)$/
        return "darwin"
      when /hpux(.+)$/
        return "hpux"
      when /linux/
        return "linux"
      when /freebsd(.+)$/
        return "freebsd"
      when /openbsd(.+)$/
        return "openbsd"
      when /netbsd(.*)$/
        return "netbsd"
      when /solaris2/
        return "solaris2"
      when /mswin|mingw32|windows/
        # After long discussion in IRC the "powers that be" have come to a concensus
        # that there is no other Windows platforms exist that were not based on the
        # Windows_NT kernel, so we herby decree that "windows" will refer to all
        # platforms built upon the Windows_NT kernel and have access to win32 or win64
        # subsystems.
        return "windows"
      else
        return ::RbConfig::CONFIG['host_os']
      end
    end

  end
end
