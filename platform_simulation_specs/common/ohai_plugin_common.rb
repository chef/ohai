
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

require 'rubygems'
require 'ffi_yajl'
require 'ohai'
require 'yaml'

module OhaiPluginCommon
  FAKE_SEP = "___"

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
    e = FFI_Yajl::Encoder.new
    <<-eos
platform "#{platform}"
arch "#{arch}"
env #{env}
params #{e.encode( params )}
stdout #{e.encode( stdout )}
stderr #{e.encode( stderr )}
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

    # Create a list of directories needed to be created before the file is created.
    # Assume that the #{path} directory exists, but that any directories included in #{cmd} may or may not.
    dir_list = cmd.split(/\//).inject( [] ) do | acc, ele |
      if acc == []
        acc << ele
      else
        acc << File.join( acc.last, ele )
      end
    end.reject { | e | e == "" }
    dir_list = dir_list.map { |e| File.join( path, e )}
    cmd_path = dir_list.pop
    bat_path = cmd_path + ".bat"

    # Ensure the directories in #{cmd} get created - this is for absolute path support
    # This is a workaround: Dir.exists? doesn't exist in 1.8.7
    dir_list.each do | e |
      exists = false
      begin
        Dir.new e
        exists = true
      rescue Errno::ENOENT
      end
      Dir.mkdir( e ) unless exists
    end

    #fake exe
    file = <<-eof
#!#{File.join( RbConfig::CONFIG['bindir'], 'ruby' )}

require 'yaml'
require '#{path}/ohai_plugin_common.rb'

OhaiPluginCommon.fake_command OhaiPluginCommon.read_output( '#{cmd.gsub( /\//, OhaiPluginCommon::FAKE_SEP )}' ), '#{platform}', '#{arch}', #{FFI_Yajl::Encoder.encode( env )}
eof
    File.open(cmd_path, "w") { |f| f.puts file }

    #.bat shim for windows
    bat = <<-eof
@#{File.join( RbConfig::CONFIG['bindir'], 'ruby' )} #{cmd_path} %1 %2 %3 %4 %5 %6 %7 %8 %9
eof
    File.open(bat_path, "w") { |f| f.puts bat }

    # sleep 0.01 until File.exists? cmd_path
    Mixlib::ShellOut.new("chmod 755 #{cmd_path}").run_command
  end

  # delete all files and folders in path except those that match
  # the specified regex
  def clean_path( path, regex )
    Dir.glob( File.join( path, "*" )).
      reject { | e | e =~ regex }.
      each { | e | Mixlib::ShellOut.new( "rm -rf #{ e }" ).run_command }
  end

  module_function( :fake_command, :data_path, :get_path, :read_output, :clean_path,
                   :to_fake_exe_format, :data_to_string, :create_exe, :plugin_path )
end

# checks to see if the elements in test are also in source.  Recursively decends into Hashes.
# nil values in test match against both nil and non-existance in source.
def subsumes?(source, test, path = [], &block)
  if source.is_a?( Hash ) && test.is_a?( Hash )
    test.all? { |k,v| subsumes?( source[k], v, path.clone << k, &block )}
  else
    block.call( path, source, test ) if block
    source == test
  end
end

# test that a plugin conforms populates ohai with the correct data
def test_plugin(plugin_names, cmd_list)
  #
  # Current platform simulation tests are disabled. Remove the line below
  # in order to enable the platform simulation tests.
  #
  return

  # clean the path directory, in case a previous test was interrupted
  OhaiPluginCommon.clean_path OhaiPluginCommon.get_path, /^.*\.rb$/

  l = lambda do | *args |
    platforms = args[0]
    archs = args[1]
    envs = args[2]
    ohai = args[3]
    pending_status = args[4] || nil
    platforms.each do |platform|
      describe "when the platform is #{platform}" do
        archs.each do |arch|
          describe "and the architecture is #{arch}" do
            envs.each do |env|
              describe "and the environment is #{env}" do
                path = OhaiPluginCommon.get_path
                cmd_not_found = Set.new

                begin
                  # preserve the path
                  old_path = ENV[ 'PATH' ]

                  # create fake executables
                  cmd_list.each do | c |
                    data = OhaiPluginCommon.read_output( c.gsub( /\//, OhaiPluginCommon::FAKE_SEP ))

                    data = data[platform][arch].select { |f| f[:env] == env }
                    if data.all? { |f| ( /not found/ =~ f[:stderr] ) && f[:exit_status] == 127 }
                      cmd_not_found.add c
                    else
                      OhaiPluginCommon.create_exe c, path, platform, arch, env
                    end
                  end

                  # capture all executions in path dir
                  ENV['PATH'] = path
                  Ohai.instance_eval do
                    def self.abs_path( abs_path )
                      File.join( OhaiPluginCommon.get_path, abs_path )
                    end
                  end

                  @ohai = Ohai::System.new
                  plugin_names.each do | plugin_name |
                    @plugin = get_plugin(plugin_name, @ohai, OhaiPluginCommon.plugin_path)
                    raise "Can not find plugin #{plugin_name}" if @plugin.nil?
                    @plugin.safe_run
                  end
                ensure
                  Ohai.instance_eval do
                    def self.abs_path( abs_path )
                      abs_path
                    end
                  end
                  ENV['PATH'] = old_path
                  OhaiPluginCommon.clean_path OhaiPluginCommon.get_path, /^.*\.rb$/
                end

                enc = FFI_Yajl::Encoder
                subsumes?( @ohai.data, ohai ) do | path, source, test |
                  path_txt = path.map { |p| "[#{enc.encode( p )}]" }.join
                  if test.nil?
                    txt = "should not set #{path_txt}"
                  else
                    txt = "should set #{path_txt} to #{enc.encode( test )}"
                  end
                  it txt do
                    pending(pending_status) if !pending_status.nil?
                    source.should eq( test )
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  # human friendlier syntax
  l.instance_exec do
    alias :test :call
  end
  yield l
end
