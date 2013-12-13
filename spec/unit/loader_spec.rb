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
  extend IntegrationSupport

  before(:each) do
    @plugin_data = Mash.new
    @provides_map = Ohai::ProvidesMap.new

    @ohai = double('Ohai::System', :data => @plugin_data, :provides_map => @provides_map)
    @loader = Ohai::Loader.new(@ohai)
  end

  describe "#initialize" do
    it "should return an Ohai::Loader object" do
      loader = Ohai::Loader.new(@ohai)
      loader.should be_a_kind_of(Ohai::Loader)
    end
  end

  when_plugins_directory "contains both V6 & V7 plugins" do
    with_plugin("zoo.rb", <<EOF)
Ohai.plugin(:Zoo) do
  provides 'seals'
end
EOF

    with_plugin("lake.rb", <<EOF)
provides 'fish'
EOF

    describe "load_plugin() method" do
      it "should load the v7 plugin correctly" do
        @loader.load_plugin(path_to("zoo.rb"))
        @provides_map.map.keys.should include("seals")
      end

      it "should load the v6 plugin correctly with a depreceation message" do
        Ohai::Log.should_receive(:warn).with(/\[DEPRECATION\]/)
        @loader.load_plugin(path_to("lake.rb"))
        @provides_map.map.should be_empty
      end

      it "should log a warning if a plugin doesn't exist" do
        Ohai::Log.should_receive(:warn).with(/Unable to open or read plugin/)
        @loader.load_plugin(path_to("rainier.rb"))
        @provides_map.map.should be_empty
      end
    end
  end

  when_plugins_directory "contains invalid plugins" do
    with_plugin("no_method.rb", <<EOF)
Ohai.plugin(:Zoo) do
  provides 'seals'
end

Ohai.blah(:Nasty) do
  provides 'seals'
end
EOF

    with_plugin("illegal_def.rb", <<EOF)
Ohai.plugin(:Zoo) do
  collect_data(:darwin) do
  end
  collect_data(:darwin) do
  end
end
EOF

    with_plugin("unexpected_error.rb", <<EOF)
Ohai.plugin(:Zoo) do
  raise "You aren't expecting this."
end
EOF

    describe "load_plugin() method" do
      it "should log a warning when plugin tries to call an unexisting method" do
        Ohai::Log.should_receive(:warn).with(/used unsupported operation/)
        lambda { @loader.load_plugin(path_to("no_method.rb")) }.should_not raise_error
      end

      it "should log a warning for illegal plugins" do
        Ohai::Log.should_receive(:warn).with(/not properly defined/)
        lambda { @loader.load_plugin(path_to("illegal_def.rb")) }.should_not raise_error
      end

      it "should not raise an error during an unexpected exception" do
        Ohai::Log.should_receive(:warn).with(/threw exception/)
        lambda { @loader.load_plugin(path_to("unexpected_error.rb")) }.should_not raise_error
      end
    end
  end

end
