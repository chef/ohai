#
# Author:: Patrick Collins (<pat@burned.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

describe Ohai::System, "Darwin Memory Plugin" do
  before do
    darwin_memsize = <<-DARWIN_MEMSIZE
17179869184
    DARWIN_MEMSIZE
    darwin_vm_stat = <<-DARWIN_VM_STAT
Mach Virtual Memory Statistics: (page size of 4096 bytes)
Pages free:                        2155305.
Pages active:                       924164.
Pages inactive:                     189127.
Pages speculative:                  531321.
Pages wired down:                   391749.
"Translation faults":             14107520.
Pages copy-on-write:                810071.
Pages zero filled:                 6981505.
Pages reactivated:                    1397.
Pageins:                            630064.
Pageouts:                                0.
Object cache: 12 hits of 139872 lookups (0% hit rate)
    DARWIN_VM_STAT

    @ohai = Ohai::System.new
    @ohai.stub!(:require_plugin).and_return(true)

    @ohai.stub(:from).with("sysctl -n hw.memsize").and_return(darwin_memsize)
    @ohai.stub(:from).with("vm_stat").and_return(darwin_vm_stat)

    @ohai._require_plugin("memory")
  end

  describe "gathering memory info" do
    before do
      @ohai._require_plugin("darwin::memory")
    end

    it "completes the run" do
      @ohai['memory'].should_not be_nil
    end

    it "detects the correct memory levels" do
      @ohai['memory']['total'].should == '16384MB'
      @ohai['memory']['active'].should == '5140MB'
      @ohai['memory']['inactive'].should == '738MB'
      @ohai['memory']['free'].should == '10504MB'
    end
  end
end
