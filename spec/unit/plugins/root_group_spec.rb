#
# Author:: Joseph Anthony Pasquale Holsten (<joseph@josephholsten.com>)
# Copyright:: Copyright (c) 2013 Joseph Anthony Pasquale Holsten
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
require "ohai/util/win32/group_helper"

describe Ohai::System, "root_group" do
  before(:each) do
    @plugin = get_plugin("root_group")
  end

  describe "unix platform", :unix_only do
    before(:each) do
      # this is deeply intertwingled. unfortunately, the law of demeter
      # apparently didn't apply to this api. we're just trying to fake
      # Etc.getgrgid(Etc.getpwnam('root').gid).name
      @pwnam = Object.new
      allow(@pwnam).to receive(:gid).and_return(0)
      allow(Etc).to receive(:getpwnam).with("root").and_return(@pwnam)
      @grgid = Object.new
      allow(Etc).to receive(:getgrgid).and_return(@grgid)
    end

    describe "with wheel group" do
      before(:each) do
        allow(@grgid).to receive(:name).and_return("wheel")
      end
      it "should have a root_group of wheel" do
        @plugin.run
        expect(@plugin[:root_group]).to eq("wheel")
      end
    end

    describe "with root group" do
      before(:each) do
        allow(@grgid).to receive(:name).and_return("root")
      end
      it "should have a root_group of root" do
        @plugin.run
        expect(@plugin[:root_group]).to eq("root")
      end
    end

    describe "platform hpux with sys group" do
      before(:each) do
        allow(@pwnam).to receive(:gid).and_return(3)
        allow(@grgid).to receive(:name).and_return("sys")
      end
      it "should have a root_group of sys" do
        @plugin.run
        expect(@plugin[:root_group]).to eq("sys")
      end
    end
    describe "platform aix with system group" do
      before(:each) do
        allow(@grgid).to receive(:name).and_return("system")
      end
      it "should have a root_group of system" do
        @plugin.run
        expect(@plugin[:root_group]).to eq("system")
      end
    end
  end

  describe "windows platform" do
    it "should return the group administrators" do
      stub_const("::RbConfig::CONFIG", { "host_os" => "windows" } )
      expect(Ohai::Util::Win32::GroupHelper).to receive(:windows_root_group_name).and_return("administrators")
      @plugin.run
      expect(@plugin[:root_group]).to eq("administrators")
    end
  end
end
