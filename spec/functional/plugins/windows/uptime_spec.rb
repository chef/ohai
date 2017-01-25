#
# Author:: Aliasgar Batterywala (<aliasgar.batterywala@msystechnologies.com>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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

require_relative "../../../spec_helper.rb"

describe Ohai::System, "Windows plugin uptime" do

  context "for newer version of Windows" do
    let(:uptime_plugin) do
      get_plugin("uptime").tap do |plugin|
        plugin[:platform_version] = "6.3.9600"
      end
    end

    let(:wmi) do
      double("wmi", { :first_of =>
        { "lastbootuptime" => "20160912103128.597219+0000" },
      })
    end

    before(:each) do
      allow(uptime_plugin).to receive(:collect_os).and_return(:windows)
      allow(WmiLite::Wmi).to receive(:new).and_return(wmi)
      allow(Time).to receive_message_chain(:new, :to_i).and_return(1473756619)
    end

    it "should set uptime_seconds to uptime" do
      uptime_plugin.run
      expect(uptime_plugin[:uptime_seconds]).to be == 80331
    end

    it "should set uptime to a human readable value" do
      uptime_plugin.run
      expect(uptime_plugin[:uptime]).to eq("22 hours 18 minutes 51 seconds")
    end
  end

  context "for older version of Windows" do
    let(:uptime_plugin) do
      get_plugin("uptime").tap do |plugin|
        plugin[:platform_version] = "5.0.2195"
      end
    end

    let(:wmi) do
      double("wmi", { :first_of =>
        { "systemuptime" => "785345" },
      })
    end

    before(:each) do
      allow(uptime_plugin).to receive(:collect_os).and_return(:windows)
      allow(WmiLite::Wmi).to receive(:new).and_return(wmi)
    end

    it "should set uptime_seconds to uptime" do
      uptime_plugin.run
      expect(uptime_plugin[:uptime_seconds]).to be == 785345
    end

    it "should set uptime to a human readable value" do
      uptime_plugin.run
      expect(uptime_plugin[:uptime]).to eq("9 days 02 hours 09 minutes 05 seconds")
    end
  end
end
