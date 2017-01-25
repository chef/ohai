#
# Author:: Claire McQuin <claire@chef.io>
# Copyright:: Copyright (c) 2015-2016 Chef Software, Inc.
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

require_relative "../spec_helper"
require "ohai/application"

RSpec.describe "Ohai::Application" do

  let(:app) { Ohai::Application.new }
  let(:argv) { [] }
  let(:stderr) { StringIO.new }

  before(:each) do
    @original_argv = ARGV.dup
    ARGV.replace(argv)
  end

  after(:each) do
    ARGV.replace(@original_argv)
  end

  describe "#configure_ohai" do

    let(:config_content) { "" }
    let(:config_dir) { Dir.mktmpdir(".chef") }
    let(:config_location) { File.join(config_dir, "config.rb") }

    before(:each) do
      File.open(config_location, "w+") do |f|
        f.write(config_content)
      end
    end

    after(:each) do
      FileUtils.rm_rf(config_dir)
    end

    context "when a configuration file is provided as a command line option" do

      let(:argv) { [ "-c", config_location + ".oops" ] }

      context "and the configuration file does not exist" do

        it "logs an error and terminates the application" do
          expect(STDERR).to receive(:puts).with(/FATAL:/)
          expect(Ohai::Log).to receive(:fatal).
            with(/Specified config file #{argv[1]} does not exist/)
          expect { app.configure_ohai }.to raise_error(SystemExit)
        end
      end
    end

    context "when a workstation configuration file exists" do

      let(:config_content) { "ohai.disabled_plugins = [ :Foo, :Baz ]" }

      # env['KNIFE_HOME']/config.rb is the first config file the workstation
      # config loader looks for:
      # https://github.com/chef/chef/blob/master/chef-config/lib/chef-config/workstation_config_loader.rb#L102
      let(:env) { { "KNIFE_HOME" => config_dir } }

      before(:each) do
        allow_any_instance_of(ChefConfig::WorkstationConfigLoader).
          to receive(:env).and_return(env)
      end

      it "loads the workstation configuration file" do
        app.configure_ohai
        expect(Ohai.config[:disabled_plugins]).to eq([ :Foo, :Baz ])
      end
    end

    context "when the configuration file has a syntax error" do
      # For the purpose of these tests it doesn't matter if the configuration
      # file was specified via command line or discovered on the local
      # workstation. It's easier if we pass the configuration file as a cli
      # argument (there's less to stub).

      let(:argv) { [ "-c", config_location ] }

      let(:config_content) { 'config_location "blaaaaa' }

      it "logs an error and terminates the application" do
        expect(STDERR).to receive(:puts).with(/FATAL:/)
        expect(Ohai::Log).to receive(:fatal).
          with(/You have invalid ruby syntax in your config file/)
        expect { app.configure_ohai }.to raise_error(SystemExit)
      end
    end

  end
end
