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

  describe '#configure_ohai' do
    it 'merges deprecated config settings into the ohai config context' do
      expect(Ohai::Config).to receive(:merge_deprecated_config)
      app.configure_ohai
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
