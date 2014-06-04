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

describe Ohai::System, "Solaris2.X cpu plugin" do
  before(:each) do
    @plugin = get_plugin("solaris2/cpu")
    @plugin.stub(:collect_os).and_return("solaris2")
    @plugin.stub(:shell_out).with("psrinfo | wc -l").and_return(mock_shell_out(0, "32\n", ""))
    @plugin.stub(:shell_out).with("psrinfo -p").and_return(mock_shell_out(0, "4\n", ""))

    psrinfo_output = <<-END.strip
    x86 (GenuineIntel 206D7 family 6 model 45 step 7 clock 2600 MHz)
      Intel(r) Xeon(r) CPU E5-2670 0 @ 2.60GHz
    x86 (CrazyTown 206D7 family 12 model 93 step 9 clock 2900 MHz)
      Intel(r) Xeon(r) CPU E5-2690 0 @ 2.90GHz
END
    @plugin.stub(:shell_out).with('psrinfo -v -p | grep Hz').and_return(mock_shell_out(0, psrinfo_output, ""))
  end
  
  it "should get the total virtual processor count" do
    @plugin.run
    @plugin['cpu']['total'].should eql(32)
  end

  it 'should get the total processor count' do
    @plugin.run
    @plugin['cpu']['real'].should eql(4)
  end

  describe 'per-cpu information' do
    it "should include vendor_id for processors" do
      @plugin.run
      @plugin['cpu']['0']['vendor_id'].should eql('GenuineIntel')
      @plugin['cpu']['1']['vendor_id'].should eql('CrazyTown')
    end

    it "should include family for processors" do
      @plugin.run
      @plugin['cpu']["0"]["family"].should eql("6")
      @plugin['cpu']["1"]["family"].should eql("12")
    end

    it "should include model for processors" do
      @plugin.run
      @plugin['cpu']["0"]["model"].should eql("45")
      @plugin['cpu']["1"]["model"].should eql("93")
    end

    it "should include stepping for processors" do
      @plugin.run
      @plugin['cpu']["0"]["stepping"].should eql("7")
      @plugin['cpu']["1"]["stepping"].should eql("9")
    end

    it "should include model name for processors" do
      @plugin.run
      @plugin['cpu']["0"]["model_name"].should eql("Intel(r) Xeon(r) CPU E5-2670 0 @ 2.60GHz")
      @plugin['cpu']["1"]["model_name"].should eql("Intel(r) Xeon(r) CPU E5-2690 0 @ 2.90GHz")
    end

    it "should include mhz name for processors" do
      @plugin.run
      @plugin['cpu']["0"]["mhz"].should eql("2600")
      @plugin['cpu']["1"]["mhz"].should eql("2900")
    end
  end
end
