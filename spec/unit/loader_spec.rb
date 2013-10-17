#
# Author:: Claire McQuin (<claire@opscode.com>)
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Ohai::Loader do
  before(:each) do
    @ohai = Ohai::System.new
  end

  describe "#initialize" do
    it "should return an Ohai::Loader object" do
      loader = Ohai::Loader.new(@ohai)
      loader.should be_a_kind_of(Ohai::Loader)
    end
  end

  describe "#load_plugin" do
    before(:each) do
      @name = :Test
      @v6name = "test"
      @path = "test.rb"

      @loader = Ohai::Loader.new(@ohai)
      @loader.stub(:collect_provides).and_return({})
    end

    it "should log a warning if a plugin cannot be loaded" do
      Ohai::Log.should_receive(:warn).with(/Unable to open or read plugin/)
      IO.stub(:read).with(anything()).and_raise(IOError)
      @loader.load_plugin("")
    end

    it "should detect a version 6 plugin and emit deprecation message" do
      contents = <<EOF
provides "test"
test Mash.new
EOF
      IO.stub(:read).with(@path).and_return(contents)
      Ohai::Log.should_receive(:warn).with(/[DEPRECATION]/)
      plugin = @loader.load_plugin(@path, @v6name)
      plugin.version.should eql(:version6)
    end

    it "should detect a version 7 plugin" do
      contents = <<EOF
Ohai.plugin(:#{@name}) do
end
EOF
      IO.stub(:read).with(@path).and_return(contents)
      plugin = @loader.load_plugin(@path)
      plugin.version.should eql(:version7)
    end

    it "should log a warning from NoMethodError when plugin uses a non dsl command" do
      contents = <<EOF
Ohai.plugin(:#{@name}) do
  requires "test"
end
EOF
      IO.stub(:read).with(@path).and_return(contents)
      Ohai::Log.should_receive(:warn).with(/[UNSUPPORTED OPERATION]/)
      @loader.load_plugin(@path)
    end
  end

  describe "#collect_provides" do
    before(:each) do
      @name = :Test
      @path = "test.rb"
      @loader = Ohai::Loader.new(@ohai)
    end

    it "should add provided attributes to Ohai" do
      klass = Ohai.plugin(@name) { provides("attr") }
      plugin = klass.new(@ohai, @path)
      @loader.collect_provides(plugin)
      @ohai.attributes.should have_key(:attr)
    end

    it "should add provided subattributes to Ohai" do
      klass = Ohai.plugin(@name) { provides("attr/sub") }
      plugin = klass.new(@ohai, @plath)
      @loader.collect_provides(plugin)
      @ohai.attributes.should have_key(:attr)
      @ohai.attributes[:attr].should have_key(:sub)
    end

    it "should collect the unique providers for an attribute" do
      n = 3
      klass = Ohai.plugin(@name) { provides("attr") }

      plugins = []
      n.times do
        plugins << klass.new(@ohai, @path)
      end

      plugins.each { |plugin| @loader.collect_provides(plugin) }
      @ohai.attributes[:attr][:_providers].should eql(plugins)
    end
  end
end
