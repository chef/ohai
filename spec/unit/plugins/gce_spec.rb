#
# Author:: Paul Rossman (<paulrossman@google.com>)
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
# WITHOUT WARRANTIES OR CONDIT"Net::HTTP Response"NS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Ohai::System, "plugin gce" do

  let(:hint_path_nix) { '/etc/chef/ohai/hints/gce.json' }
  let(:hint_path_win) { 'C:\chef\ohai\hints/gce.json' }

  before do
    @ohai = Ohai::System.new
    @ohai.stub(:require_plugin).and_return(true)
  end

  shared_examples_for "!gce"  do
    it "should not create the gce mash" do
      @ohai._require_plugin("gce")
      @ohai[:gce].should be_nil
    end
  end

  shared_examples_for "gce" do
    it "should create the gce mash" do
      @ohai._require_plugin("gce")
      @ohai[:gce].should_not be_nil
    end
    it "should have the instance attribute" do
      @ohai._require_plugin("gce")
      @ohai[:gce][:instance].should.should_not be_nil
    end
  end

  context "with gce hint file" do
    before do
      File.stub(:exist?).with(hint_path_nix).and_return(true)
      File.stub(:read).with(hint_path_nix).and_return('')
      File.stub(:exist?).with(hint_path_win).and_return(true)
      File.stub(:read).with(hint_path_win).and_return('')
    end
    it_should_behave_like "gce"
  end

  context "without hint file" do
    before do
      File.stub(:exist?).with(hint_path_nix).and_return(false)
      File.stub(:exist?).with(hint_path_win).and_return(false)
    end
    it_should_behave_like "!gce"
  end

  context "with ec2 hint file" do
    let(:hint_path_nix) { '/etc/chef/ohai/hints/ec2.json' }
    let(:hint_path_win) { 'C:\chef\ohai\hints/ec2.json' }
    before do
      File.stub(:exist?).with(hint_path_nix).and_return(true)
      File.stub(:read).with(hint_path_nix).and_return('')
      File.stub(:exist?).with(hint_path_win).and_return(true)
      File.stub(:read).with(hint_path_win).and_return('')
    end
    it_should_behave_like "!gce"
  end

end
