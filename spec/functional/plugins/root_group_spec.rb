#
# Author:: Adam Edwards (<adamed@getchef.com>)
#
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Ohai::System, 'root_group plugin' do
  before(:each) do
    @plugin = get_plugin("root_group")
  end

  describe 'windows platform', :windows_only do
    let (:wmi) {  wmi = WmiLite::Wmi.new }

    it 'should return the system\'s administrators (root) group' do
      # This query may be slow on domain-joined systems if there are connectivity
      # issues to the domain controller or there are a lot of groups since the
      # provider for Win32_Group attempts to read groups from Active Directory
      groups = wmi.query("select * from Win32_Group where sid = 'S-1-5-32-544'")
      groups.length.should == 1
      administrators_group = groups[0]['name'].downcase
      @plugin.run
      @plugin[:root_group].downcase.should == administrators_group
    end
  end
end
