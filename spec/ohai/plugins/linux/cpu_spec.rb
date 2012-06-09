#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

describe Ohai::System, "Linux cpu plugin" do
  before(:each) do
    @ohai = Ohai::System.new
    @ohai.stub!(:require_plugin).and_return(true)
    @ohai[:os] = "linux"
    @contents = [
      "processor     : 0",
      "vendor_id     : GenuineIntel",
      "cpu family    : 6",
      "model         : 23",
      "model name    : Intel(R) Core(TM)2 Duo CPU     T8300   @ 2.40GHz",
      "stepping      : 6",
      "cpu MHz       : 1968.770",
      "cache size    : 64 KB",
      "fdiv_bug      : no",
      "hlt_bug       : no",
      "f00f_bug      : no",
      "coma_bug      : no",
      "fpu           : yes",
      "fpu_exception : yes",
      "cpuid level   : 10",
      "wp            : yes",
      "flags         : fpu pse tsc msr mce cx8 sep mtrr pge cmov",
      "bogomips      : 2575.86",
      "clflush size  : 32" ]
    File.stub!(:read_procfile).with("/proc/cpuinfo").and_return(@contents)
  end

  it "should read non-blocking succesfully" do
   File.should_receive(:read_procfile).with("/proc/cpuinfo").and_return(@contents)
   @ohai._require_plugin("linux::cpu")
  end

  it "should set cpu[:total] to 1" do
    @ohai._require_plugin("linux::cpu")
    @ohai[:cpu][:total].should == 1
  end

  it "should set cpu[:real] to 0" do
    @ohai._require_plugin("linux::cpu")
    @ohai[:cpu][:real].should == 0
  end

  it "should have a cpu 0" do
    @ohai._require_plugin("linux::cpu")
    @ohai[:cpu].should have_key("0")
  end

  it "should have a vendor_id for cpu 0" do
    @ohai._require_plugin("linux::cpu")
    @ohai[:cpu]["0"].should have_key("vendor_id")
    @ohai[:cpu]["0"]["vendor_id"].should eql("GenuineIntel")
  end

  it "should have a family for cpu 0" do
    @ohai._require_plugin("linux::cpu")
    @ohai[:cpu]["0"].should have_key("family")
    @ohai[:cpu]["0"]["family"].should eql("6")
  end

  it "should have a model for cpu 0" do
    @ohai._require_plugin("linux::cpu")
    @ohai[:cpu]["0"].should have_key("model")
    @ohai[:cpu]["0"]["model"].should eql("23")
  end

  it "should have a stepping for cpu 0" do
    @ohai._require_plugin("linux::cpu")
    @ohai[:cpu]["0"].should have_key("stepping")
    @ohai[:cpu]["0"]["stepping"].should eql("6")
  end

  it "should not have a phyiscal_id for cpu 0" do
    @ohai._require_plugin("linux::cpu")
    @ohai[:cpu]["0"].should_not have_key("physical_id")
  end

  it "should not have a core_id for cpu 0" do
    @ohai._require_plugin("linux::cpu")
    @ohai[:cpu]["0"].should_not have_key("core_id")
  end

  it "should not have a cores for cpu 0" do
    @ohai._require_plugin("linux::cpu")
    @ohai[:cpu]["0"].should_not have_key("cores")
  end

  it "should have a model name for cpu 0" do
    @ohai._require_plugin("linux::cpu")
    @ohai[:cpu]["0"].should have_key("model_name")
    @ohai[:cpu]["0"]["model_name"].should eql("Intel(R) Core(TM)2 Duo CPU     T8300   @ 2.40GHz")
  end

  it "should have a mhz for cpu 0" do
    @ohai._require_plugin("linux::cpu")
    @ohai[:cpu]["0"].should have_key("mhz")
    @ohai[:cpu]["0"]["mhz"].should eql("1968.770")
  end

  it "should have a cache_size for cpu 0" do
    @ohai._require_plugin("linux::cpu")
    @ohai[:cpu]["0"].should have_key("cache_size")
    @ohai[:cpu]["0"]["cache_size"].should eql("64 KB")
  end

  it "should have flags for cpu 0" do
    @ohai._require_plugin("linux::cpu")
    @ohai[:cpu]["0"].should have_key("flags")
    @ohai[:cpu]["0"]["flags"].should == %w{fpu pse tsc msr mce cx8 sep mtrr pge cmov}
  end
end
