#
# Author:: Adam Edwards (<adamed@chef.io>)
#
# Copyright:: Copyright (c) 2014-2016 Chef Software, Inc.
#
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

require_relative "../../spec_helper.rb"

describe Ohai::System, "root_group plugin" do
  let(:plugin) { get_plugin("root_group") }

  describe "windows platform", :windows_only do
    let (:wmi) { wmi = WmiLite::Wmi.new }

    it 'should return the system\'s administrators (root) group' do
      # Notethat the Win32_Group WMI provider can be slow if your
      # system is domain-joined and has hundreds of thousands of
      # groups in Active Directory -- not a typical test scenario, but
      # something to watch if you run this test in such an environment.
      groups = wmi.query("select * from Win32_Group where sid = 'S-1-5-32-544'")
      expect(groups.length).to eq(1)
      administrators_group = groups[0]["name"].downcase
      plugin.run
      expect(plugin[:root_group].downcase).to be == administrators_group
    end
  end
end
