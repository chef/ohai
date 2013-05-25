#
# Author:: Will Maier (<will@simple.com>)
# Copyright:: Copyright (c) 2013 Simple Finance Technology, Inc.
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

describe Ohai::System, "Linux getconf plugin" do
  before(:each) do
    @ohai = Ohai::System.new
  end

  it "should parse getconf output" do
    @status = 0
    @stdout = "PAGE_SIZE __PAGE_SIZE__\n"
    @stderr = ""
    @ohai.stub!(:run_command).with({
                                   :no_status_check=>true,
                                   :command=>"getconf -a"
                                   }).and_return([
                                                @status,
                                                @stdout,
                                                @stderr])
    @ohai._require_plugin("linux/getconf")
    @ohai.getconf[:PAGE_SIZE].should eql("__PAGE_SIZE__")
  end

  it "should handle getconf failure" do
    @status = 1
    @stdout = ""
    @stderr = "whops\n"
    @ohai.stub!(:run_command).with({
                                   :no_status_check=>true,
                                   :command=>"getconf -a"
                                   }).and_return([
                                                @status,
                                                @stdout,
                                                @stderr])
    @ohai._require_plugin("linux/getconf")
    @ohai.getconf[:PAGE_SIZE].should eql(nil)
  end

end
