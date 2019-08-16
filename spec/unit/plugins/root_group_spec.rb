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

require "spec_helper"

describe Ohai::System, "root_group" do
  before do
    @plugin = get_plugin("root_group")
  end

  describe "unix platform", :unix_only do
    before do
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
      before do
        allow(@grgid).to receive(:name).and_return("wheel")
      end

      it "has a root_group of wheel" do
        @plugin.run
        expect(@plugin[:root_group]).to eq("wheel")
      end
    end

    describe "with root group" do
      before do
        allow(@grgid).to receive(:name).and_return("root")
      end

      it "has a root_group of root" do
        @plugin.run
        expect(@plugin[:root_group]).to eq("root")
      end
    end

    describe "platform aix with system group" do
      before do
        allow(@grgid).to receive(:name).and_return("system")
      end

      it "has a root_group of system" do
        @plugin.run
        expect(@plugin[:root_group]).to eq("system")
      end
    end
  end

  describe "windows platform" do

    let(:wmi) { double("wmi", { query: "" }) }

    before do
      allow(WmiLite::Wmi).to receive(:new).and_return(wmi)
      allow(@plugin).to receive(:collect_os).and_return(:windows)
    end

    it "returns the group Administrators" do
      expect(wmi)
        .to receive(:query)
        .with("select * from Win32_Group where sid like 'S-1-5-32-544' and LocalAccount=True")
        .and_return("Administrators")

      @plugin.run
    end
  end
end
