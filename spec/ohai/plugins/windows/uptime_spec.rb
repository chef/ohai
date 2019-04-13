#
# Author:: Franklin Webber (<franklin.webber@gmail.com>)
# Copyright:: Copyright (c) 2019 Franklin Webber
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

require 'spec_helper'

describe_ohai_plugin :Uptime do
  let(:plugin_file) { 'uptime' }

  it 'provides attributes' do
    expect(plugin).to provide_attribute('uptime')
    expect(plugin).to provide_attribute('uptime_seconds')
    expect(plugin).to provide_attribute('idletime')
    expect(plugin).to provide_attribute('idletime_seconds')
  end

  context 'windows' do
    let(:platform) { 'windows'}
    let(:time_now) { Time.parse('2019-04-13 01:02:06 -0500') }

    it 'has uptime' do
      allow(plugin).to receive(:time_now).and_return(time_now)
      allow(plugin).to receive(:shell_out).and_return(double(stdout:'20160912103128.597219+0000'))
      expect(plugin_attribute('uptime')).to eq('942 days 19 hours 30 minutes 38 seconds')
    end

    it 'has uptime_seconds' do
      allow(plugin).to receive(:time_now).and_return(time_now)
      allow(plugin).to receive(:shell_out).and_return(double(stdout:'20160912103128.597219+0000'))
      expect(plugin_attribute('uptime_seconds')).to eq(81459038)
    end
  end
end
