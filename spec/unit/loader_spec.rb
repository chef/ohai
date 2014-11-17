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
      expect(loader).to be_a_kind_of(Ohai::Loader)
    end
  end

  when_plugins_directory "contains both V6 & V7 plugins" do
    with_plugin("zoo.rb", <<EOF)
Ohai.plugin(:Zoo) do
  provides 'seals'
end
EOF

    with_plugin("zoo_too.rb", <<EOF)
Ohai.plugin(:Zoo) do
  provides 'elephants'
end
EOF

    with_plugin("lake.rb", <<EOF)
provides 'fish'
EOF

    describe "load_plugin() method" do
      describe "when loading a v7 plugin" do
        before(:each) do
          @plugin = @loader.load_plugin(path_to("zoo.rb"))
        end          

        it "should save the plugin according to its attribute" do          
          expect(@provides_map.map.keys).to include("seals")
        end

        it "should save a single plugin source" do
          expect(@plugin.source).to eql([path_to("zoo.rb")])
        end

        it "should save all plugin sources" do
          @loader.load_plugin(path_to("zoo_too.rb"))
          expect(@plugin.source).to eql([path_to("zoo.rb"), path_to("zoo_too.rb")])
        end
      end

      describe "when loading a v6 plugin" do
        before(:each) do
          expect(Ohai::Log).to receive(:warn).with(/\[DEPRECATION\]/)
          @plugin = @loader.load_plugin(path_to("lake.rb"), path_to("."))
        end

        it "should not add this plugin's provided attributes to the provides map" do
          expect(@provides_map.map).to be_empty
        end

        it "should save the plugin's source" do
          expect(@plugin.source).to eql(path_to("lake.rb"))
        end
      end

      it "should log a warning if a plugin doesn't exist" do
        expect(Ohai::Log).to receive(:warn).with(/Unable to open or read plugin/)
        @loader.load_plugin(path_to("rainier.rb"), path_to("."))
        expect(@provides_map.map).to be_empty
      end
    end
  end

  when_plugins_directory "contains invalid plugins" do
    with_plugin("extra_s.rb", <<EOF)
Ohai.plugins(:ExtraS) do
  provides "the_letter_s"
end
EOF

    with_plugin("no_method.rb", <<EOF)
Ohai.plugin(:NoMethod) do
  really_wants "this_attribute"
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

    with_plugin("bad_symbol.rb", <<EOF)
Ohai.plugin(:1nval!d) do
  provides "not_a_symbol"
end
EOF

    with_plugin("no_end.rb", <<EOF)
Ohai.plugin(:NoEnd) do
  provides "fish_oil"
  collect_data do
end
EOF

    with_plugin("bad_name.rb", <<EOF)
Ohai.plugin(:you_give_plugins_a_bad_name) do
  provides "that/one/song"
end
EOF

    describe "load_plugin() method" do
      describe "when the plugin uses Ohai.plugin instead of Ohai.plugins" do
        it "should log an unsupported operation warning" do
          expect(Ohai::Log).to receive(:warn).with(/Plugin Method Error: <#{path_to("extra_s.rb")}>:/)
          @loader.load_plugin(path_to("extra_s.rb"))
        end

        it "should not raise an error" do
          expect{ @loader.load_plugin(path_to("extra_s.rb")) }.not_to raise_error
        end
      end

      describe "when the plugin tries to call an unexisting method" do
        it "shoud log an unsupported operation warning" do
          expect(Ohai::Log).to receive(:warn).with(/Plugin Method Error: <#{path_to("no_method.rb")}>:/)
          @loader.load_plugin(path_to("no_method.rb"))
        end

        it "should not raise an error" do
          expect{ @loader.load_plugin(path_to("no_method.rb")) }.not_to raise_error
        end
      end

      describe "when the plugin defines collect_data on the same platform more than once" do
        it "shoud log an illegal plugin definition warning" do
          expect(Ohai::Log).to receive(:warn).with(/Plugin Definition Error: <#{path_to("illegal_def.rb")}>:/)
          @loader.load_plugin(path_to("illegal_def.rb"))
        end

        it "should not raise an error" do
          expect{ @loader.load_plugin(path_to("illegal_def.rb")) }.not_to raise_error
        end
      end

      describe "when an unexpected error is encountered" do
        it "should log a warning" do
          expect(Ohai::Log).to receive(:warn).with(/Plugin Error: <#{path_to("unexpected_error.rb")}>:/)
          @loader.load_plugin(path_to("unexpected_error.rb"))
        end

        it "should not raise an error" do
          expect{ @loader.load_plugin(path_to("unexpected_error.rb")) }.not_to raise_error
        end
      end

      describe "when the plugin name symbol has bad syntax" do
        it "should log a syntax error warning" do
          expect(Ohai::Log).to receive(:warn).with(/Plugin Syntax Error: <#{path_to("bad_symbol.rb")}>:/)
          @loader.load_plugin(path_to("bad_symbol.rb"))
        end

        it "should not raise an error" do
          expect{ @loader.load_plugin(path_to("bad_symbol.rb")) }.not_to raise_error
        end
      end

      describe "when the plugin forgets an 'end'" do
        it "should log a syntax error warning" do
          expect(Ohai::Log).to receive(:warn).with(/Plugin Syntax Error: <#{path_to("no_end.rb")}>:/)
          @loader.load_plugin(path_to("no_end.rb"))
        end

        it "should not raise an error" do
          expect{ @loader.load_plugin(path_to("no_end.rb")) }.not_to raise_error
        end
      end

      describe "when the plugin has an invalid name" do
        it "should log an invalid plugin name warning" do
          expect(Ohai::Log).to receive(:warn).with(/Plugin Name Error: <#{path_to("bad_name.rb")}>:/)
          @loader.load_plugin(path_to("bad_name.rb"))
        end

        it "should not raise an error" do
          expect{ @loader.load_plugin(path_to("bad_name.rb")) }.not_to raise_error
        end
      end
    end
  end
end
