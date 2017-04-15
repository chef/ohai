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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Ohai::System, "Smartos memory plugin" do
  before(:each) do
    @plugin = get_plugin("smartos/memory")
    @plugin[:os] = "smartos"
    @plugin.stub(:from).with("prtconf -m").and_return("8194")
  end

  it "should get the total memory" do
    @plugin.run
    @plugin['memory']['total'].should eql(8194)
  end
end
