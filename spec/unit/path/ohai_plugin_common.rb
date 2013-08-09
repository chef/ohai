
# Author:: Theodore Nordsieck <theo@opscode.com>
# Copyright:: Copyright (c) 2013 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'json'
require 'rspec'
require 'ohai'
require 'yaml'

module OhaiPluginCommon
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
  
  def data_path
    File.expand_path(File.dirname(__FILE__) + '../../../data/plugins')
  end
  
  def get_path(path = '')
    File.expand_path(File.dirname(__FILE__) + path)
  end

  def plugin_path
    get_path '/../../../lib/ohai/plugins'
  end
  
  #checks to see if the elements in test are also in source.  Recursively decends into Hashes.
  #nil values in test match against both nil and non-existance in source.
  def subsumes?(source, test)
    if source.is_a?( Hash ) && test.is_a?( Hash )
      test.all? { |k,v| subsumes?( source[k], v )}
    else
      source == test
    end
  end

  # read in the data file for fake executables
  def read_output( cmd, path = "#{data_path}" )

    #using an anonymous class to minimize scoping issues.
    @data = Class.new do
      @instances

      #DSL - make a list of hashes with 
      def push(param, value)
        @instances ||= []
        @instances[0] ||= {}
        current = {}
        current = @instances.pop if @instances.last[param].nil?
        current[param] = value
        @instances << current
      end
      @methods = [:platform, :arch, :env, :params, :stdout, :stderr, :exit_status]
      @methods.each { |m| self.send(:define_method, m.to_s) { |text| push m.to_sym, text }}

      #Format data into a form the rest of the app expects
      def process
        data = {}

        @instances ||= []

        @instances.each do |i|
          data[i[:platform]] ||= {}
          data[i[:platform]][i[:arch]] ||= []
          data[i[:platform]][i[:arch]] << i.reject { |k,v| k == :platform || k == :arch }
        end
        data
      end
    end

    @data = @data.new
    @data.instance_eval( File.read( "#{path}/#{cmd}.output" ))
    @data.process
  end

  # output a fake executable case in the DSL
  def to_fake_exe_format(platform, arch, env, params, stdout, stderr, exit_status)
    <<-eos
platform "#{platform}"
arch "#{arch}"
env #{env}
params #{params.to_json}
stdout #{stdout.to_json}
stderr #{stderr.to_json}
exit_status #{exit_status}
eos
  end

  # prep fake executable data for writing to a file
  def data_to_string(data)
    a = data.map do |platform,v| 
      v.map do |arch,v| 
        v.map do |e| 
          to_fake_exe_format platform, arch, e[:env], e[:params], e[:stdout], e[:stderr], e[:exit_status]
        end
      end
    end
    a.flatten.join( "\n" )
  end

  def create_exe(cmd, path, platform, arch, env)
    cmd_path = path + "/" + cmd
    file = <<-eof
#!#{File.join( RbConfig::CONFIG['bindir'], 'ruby' )}

require 'yaml'
require '#{path}/ohai_plugin_common.rb'

OhaiPluginCommon.fake_command OhaiPluginCommon.read_output( '#{cmd}' ), '#{platform}', '#{arch}', #{env}
eof
    File.open(cmd_path, "w") { |f| f.puts file }
    sleep 0.01 until File.exists? cmd_path
    Mixlib::ShellOut.new("chmod 755 #{cmd_path}").run_command
  end

  module_function( :fake_command, :data_path, :get_path, :subsumes?, :read_output,
                   :to_fake_exe_format, :data_to_string, :create_exe, :plugin_path )
end

# for use in plugins
shared_context "cross platform data" do
  shared_examples_for "a plugin" do |plugin_names, data, cmd_list|
    data.each do |e|
      next if RUBY_PLATFORM =~ /cygwin|windows|mingw/ #disable for windows

      e[:platform].each do |platform|
        e[:arch].each do |arch|
          e[:env].each do |env|
            it "provides data when the platform is '#{platform}', the architecture is '#{arch}' and the environment is '#{env}'" do
              path = OhaiPluginCommon.get_path
              cmd_not_found = Set.new

              cmd_list.each do |c|
                data = OhaiPluginCommon.read_output c
                data = data[platform][arch].select { |f| f[:env] == env }
                if data.all? { |f| /command not found/ =~ f[:stderr] && f[:exit_status] == 127 }
                  cmd_not_found.add c
                else
                  OhaiPluginCommon.create_exe c, path, platform, arch, env
                end
              end

              old_path = ENV['PATH']
              ENV['PATH'] = path

              @ohai = Ohai::System.new

              begin
                plugin_names.each do | plugin_name |
                  Ohai::Loader.new( @ohai ).load_plugin( File.join( OhaiPluginCommon.plugin_path, plugin_name + ".rb" ), plugin_name )
                  @plugin = @ohai.plugins[plugin_name.to_sym][:plugin].new( @ohai )
                  @plugin.safe_run
                end
              ensure
                ENV['PATH'] = old_path
                cmd_list.each { |c| Mixlib::ShellOut.new("rm #{path}/#{c}").run_command if !cmd_not_found.include?( c )}
              end

              OhaiPluginCommon.subsumes?( @ohai.data, e[:ohai] ).should be_true
            end
          end
        end
      end
    end
  end
end
