require 'json'
require 'rspec'

class OhaiPluginCommon

  def fake_command(data)

    # If the platform or architecture aren't set, take the first one
    platform = ENV['OHAI_TEST_PLATFORM']
    arch = ENV['OHAI_TEST_ARCH']
    env = ENV['OHAI_TEST_ENVIRONMENT']

    env = JSON.load(env)

    argv = ARGV.map { |arg| if /\ / =~ arg then "\"" + arg + "\"" else arg end }.join ' '
    match = data[platform][arch].select{ |v| v[:params] == argv && v[:env] == env }
    
    raise "No canned output for these settings." if match.empty?
    raise "More than one set of data matches these parameters." if match.size > 1
    match = match[0]
    
    $stdout.puts match[:stdout] if match[:stdout] != ''
    $stderr.puts match[:stderr] if match[:stderr] != ''
    exit match[:exit_status]
  end

  def set_path(path)
    ENV['PATH'] = File.expand_path(File.dirname(__FILE__) + path)
  end

  def set_env(platform = nil, arch = nil, env = nil)
    ENV['OHAI_TEST_PLATFORM'] = platform.to_s if !platform.nil?
    ENV['OHAI_TEST_ARCH'] = arch.to_s if !arch.nil?
    ENV['OHAI_TEST_ENVIRONMENT'] = env.to_json if !env.nil?
  end

  # monkey patch the Hash class?  I don't like the idea, but it seems like it would be idiomatic
  def subsumes?(greater, lesser)
    return greater == lesser unless lesser.instance_of? Hash
    return true if lesser.empty?
    # lesser.all?{ |k,v| greater[k] == v || ( greater[k].instance_of?( Hash ) && subsumes?( greater[k], lesser[k] ))}
    lesser.map { |k,v| greater.key?( k ) && subsumes?( greater[k], v )}
  end
end
