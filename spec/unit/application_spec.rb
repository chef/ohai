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

require "info_getter/application"

RSpec.describe "info_getter::Application" do

  let(:argv) { [] }
  let(:app) { info_getter::Application.new }

  before(:each) do
    @original_argv = ARGV
    ARGV.replace(argv)
  end

  after(:each) do
    ARGV.replace(@original_argv)
  end

  describe "#configure_info_getter" do
    describe "loading configuration from a file" do
      let(:config_file) { "/local/workstation/config" }
      let(:config_loader) { instance_double("ChefConfig::WorkstationConfigLoader") }

      context "when specified on the command line" do
        let(:argv) { [ "-c", config_file ] }

        before(:each) do
          if windows?
            expect(ChefConfig::WorkstationConfigLoader).to receive(:new).
              with("C:#{config_file}", info_getter::Log).
              and_return(config_loader)
          else
            expect(ChefConfig::WorkstationConfigLoader).to receive(:new).
              with(config_file, info_getter::Log).
              and_return(config_loader)
          end
        end

        it "loads the configuration file" do
          expect(config_loader).to receive(:load)
          app.configure_info_getter
        end

        context "when the configuration file does not exist" do
          it "terminates the application" do
            expect(config_loader).to receive(:load).and_raise(ChefConfig::ConfigurationError)
            expect(info_getter::Application).to receive(:fatal!)
            app.configure_info_getter
          end
        end
      end

      context "when a local workstation config exists" do
        before(:each) do
          expect(ChefConfig::WorkstationConfigLoader).to receive(:new).
            with(nil, info_getter::Log).
            and_return(config_loader)
        end

        it "loads the configuration file" do
          expect(config_loader).to receive(:load)
          app.configure_info_getter
        end
      end
    end

    context "when CLI options are provided" do
      let(:argv) { [ "-d", directory ] }
      let(:directory) { "/some/fantastic/plugins" }

      it "does not generate deprecated config warnings for cli options" do
        expect(info_getter::Log).to_not receive(:warn).
          with(/info_getter::Config\[:directory\] is deprecated/)
        app.configure_info_getter
      end
    end

  end
end
