require 'json'
require 'rspec'
require 'ohai'
require 'yaml'

class OhaiPluginCommon
  def fake_command(data, platform, arch, env)

    # If the platform or architecture aren't set, take the first one
    # platform = ENV['OHAI_TEST_PLATFORM']
    # arch = ENV['OHAI_TEST_ARCH']
    # env = ENV['OHAI_TEST_ENVIRONMENT']

    # env = JSON.load(env)

    argv = ARGV.map { |arg| if /\ / =~ arg then "\"" + arg + "\"" else arg end }.join ' '
    match = data[platform][arch].select{ |v| v[:params] == argv && v[:env] == env }
    
    raise "No canned output for these settings." if match.empty?
    raise "More than one set of data matches these parameters." if match.size > 1
    match = match[0]
    
    $stdout.puts match[:stdout] if match[:stdout] != ''
    $stderr.puts match[:stderr] if match[:stderr] != ''
    exit match[:exit_status]
  end

  def data_path()
    File.expand_path(File.dirname(__FILE__) + '../../../data/plugins')
  end

  def get_path(path)
    File.expand_path(File.dirname(__FILE__) + path)
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
    return greater == lesser unless ((lesser.instance_of?( Hash ) || lesser.instance_of?( Mash )) && (greater.instance_of?( Hash ) || greater.instance_of?( Mash )))
    # return true if lesser.empty?
    # lesser.all?{ |k,v| greater[k] == v || ( greater[k].instance_of?( Hash ) && subsumes?( greater[k], lesser[k] ))}
    lesser.all? { |k,v| subsumes?( greater[k], v )}
  end

  def check_expected(plugin_names, expected_data, cmd_list)
    RSpec.describe "cross platform data" do
      expected_data.each do |e|
        it "provides data when the platform is '#{e[:platform]}', the architecture is '#{e[:arch]}' and the environment is '#{e[:env]}'" do
          @opc = OhaiPluginCommon.new
          path = @opc.get_path '/../path'

          cmd_not_found = Set.new
   
          cmd_list.each do |c|
            data = YAML::load_file @opc.data_path + "/" + c + ".yaml"
            data = data[e[:platform]][e[:arch]].select { |f| f[:env] == e[:env] }
            if data.all? { |f| /command not found/ =~ f[:stderr] && f[:exit_status] == 127 }
              cmd_not_found.add c
            else
              @opc.create_exe c, path, e[:platform], e[:arch], e[:env]
            end
          end


          old_path = ENV['PATH']
          ENV['PATH'] = path
          
          @ohai = Ohai::System.new

          begin
            plugin_names.each{ |plugin_name| @ohai.require_plugin plugin_name }
          ensure
            ENV['PATH'] = old_path
            cmd_list.each { |c| Mixlib::ShellOut.new("rm #{path}/#{c}").run_command if !cmd_not_found.include?( c ) }
          end
          
          @opc.subsumes?(@ohai.data, e[:ohai]).should be_true
        end
      end
    end
  end
  
  def create_exe(cmd, path, platform, arch, env)
    
    cmd_path = path + "/" + cmd
    file = <<-eof
#!#{RbConfig.ruby}

require 'yaml'
require '#{path}/ohai_plugin_common.rb'

OhaiPluginCommon.new.fake_command YAML::load_file('#{data_path}/#{cmd}.yaml'), '#{platform}', '#{arch}', #{env}
eof
    File.open(cmd_path, "w") { |f| f.puts file }
    sleep 0.01 until File.exists? cmd_path
    Mixlib::ShellOut.new("chmod 755 #{cmd_path}").run_command
  end
end
