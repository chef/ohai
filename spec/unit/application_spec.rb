#
# Author:: Claire McQuin <claire@chef.io>
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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

require_relative '../spec_helper'

require 'ohai/application'

RSpec.describe 'Ohai::Application' do

  let(:argv) { [] }
  let(:app) { Ohai::Application.new }

  before(:each) do
    @original_argv = ARGV
    ARGV.replace(argv)
  end

  after(:each) do
    ARGV.replace(@original_argv)
  end

  def stub_fatal!(expected_message)
    expect(STDERR).to receive(:puts).with(expected_message)
    expect(Ohai::Log).to receive(:fatal).with(expected_message)
  end

  describe '#configure_ohai' do
    it 'merges deprecated config settings into the ohai config context' do
      expect(Ohai::Config).to receive(:merge_deprecated_config)
      app.configure_ohai
    end

    describe 'loading configuration from a file' do
      let(:config_file) { '/local/workstation/config' }
      let(:config_loader) { instance_double('ChefConfig::WorkstationConfigLoader') }

      context 'when specified on the command line' do
        let(:argv) { [ '-c', config_file ] }

        before(:each) do
          if windows?
            expect(ChefConfig::WorkstationConfigLoader).to receive(:new).
              with("C:#{config_file}", Ohai::Log).
              and_return(config_loader)
          else
            expect(ChefConfig::WorkstationConfigLoader).to receive(:new).
              with(config_file, Ohai::Log).
              and_return(config_loader)
          end
        end

        it 'loads the configuration file' do
          expect(config_loader).to receive(:path_exists?).
            with(config_file).
            and_return(true)
          expect(config_loader).to receive(:config_location).
            and_return(config_file)
          expect(Ohai::Config).to receive(:from_file).
            with(config_file)
          app.configure_ohai
        end

        context 'when the configuration file does not exist' do
          let(:expected_message) { Regexp.new("#{config_file} does not exist") }

          it 'terminates the application' do
            expect(config_loader).to receive(:path_exists?).
              with(config_file).
              and_return(false)
            expect(Ohai::Application).to receive(:fatal!).
              with(expected_message).
              and_call_original
            stub_fatal!(expected_message)
            expect { app.configure_ohai }.to raise_error(SystemExit)
          end
        end
      end

      context 'when a local workstation config exists' do
        before(:each) do
          expect(ChefConfig::WorkstationConfigLoader).to receive(:new).
            with(nil, Ohai::Log).
            and_return(config_loader)
        end

        it 'loads the configuration file' do
          expect(config_loader).to receive(:config_location).
            and_return(config_file)
          expect(Ohai::Config).to receive(:from_file).
            with(config_file)
          app.configure_ohai
        end
      end
    end

    context 'when CLI options are provided' do
      let(:argv) { [ '-d', directory ] }
      let(:directory) { '/some/fantastic/plugins' }

      it 'does not generate deprecated config warnings for cli options' do
        expect(Ohai::Log).to_not receive(:warn).
          with(/Ohai::Config\[:directory\] is deprecated/)
        app.configure_ohai
      end

      it 'merges CLI options into the ohai config context' do
        app.configure_ohai
        expect(Ohai.config[:directory]).to eq(directory)
      end
    end

    context 'when directory is configured' do
      let(:directory) { '/some/fantastic/plugins' }

      shared_examples_for 'directory' do
        it 'adds directory to plugin_path' do
          app.configure_ohai
          expect(Ohai.config[:plugin_path]).to include(directory)
        end
      end

      context 'in a configuration file' do
        before do
          allow(Ohai::Log).to receive(:warn).
            with(/Ohai::Config\[:directory\] is deprecated/)
          Ohai::Config[:directory] = directory
        end

        include_examples 'directory'
      end

      context 'as a command line option' do
        let(:argv) { ['-d', directory] }

        include_examples 'directory'
      end
    end

  end

end
