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

describe Ohai::System, "Windows cpu plugin", :windows_only do
  before do
    require "wmi-lite/wmi"
    @plugin = get_plugin("windows/cpu")
    mock_processor = { 
                "description"=>"Intel64 Family 6 Model 60 Stepping 3", 
                "deviceid"=>"CPU0", 
                "family"=>198, 
                "maxclockspeed"=>3401,
                "manufacturer"=>"GenuineIntel",
                "numberofcores"=>4, 
                "numberoflogicalprocessors"=>8,  
                "l2cachesize"=>1024,
                "revision"=>15363, 
                "stepping"=>"3"
              }
    mock_processors = [mock_processor,mock_processor]
    expect_any_instance_of(WmiLite::Wmi).to receive(:instances_of).
      with('Win32_Processor').and_return(mock_processors)
  end

  it "should get total processors" do
    @plugin.run
    expect(@plugin[:cpu][:total]).to eql(16)
  end

  it "should get total cores" do
    @plugin.run
    expect(@plugin[:cpu][:cores]).to eql(8)
  end

  it "should get real processors" do
    @plugin.run
    expect(@plugin[:cpu][:real]).to eql(2)
  end

  it "should have 2 cpus" do
    @plugin.run
    expect(@plugin[:cpu]).to have_key("0")
    expect(@plugin[:cpu]).to have_key("1")
  end

  it "has a vendor_id for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("vendor_id")
    expect(@plugin[:cpu]["0"]["vendor_id"]).to eql("GenuineIntel")
  end

  it "has a family for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("family")
    expect(@plugin[:cpu]["0"]["family"]).to eql("198")
  end

  it "has a model for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("model")
    expect(@plugin[:cpu]["0"]["model"]).to eql("15363")
  end

  it "has a stepping for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("stepping")
    expect(@plugin[:cpu]["0"]["stepping"]).to eql("3")
  end

   it "has a physical_id for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("physical_id")
    expect(@plugin[:cpu]["0"]["physical_id"]).to eql("CPU0")
  end

  it "has a model name for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("model_name")
    expect(@plugin[:cpu]["0"]["model_name"]).to eql("Intel64 Family 6 Model 60 Stepping 3")
  end

  it "has a mhz for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("mhz")
    expect(@plugin[:cpu]["0"]["mhz"]).to eql("3401")
  end

  it "has a cache_size for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("cache_size")
    expect(@plugin[:cpu]["0"]["cache_size"]).to eql("1024 KB")
  end

end