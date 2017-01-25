#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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

require_relative "../spec_helper.rb"

describe "Ohai::Hints" do
  # We are using the plugins directory infrastructure to test hints
  extend IntegrationSupport

  before do
    @original_hints = Ohai.config[:hints_path]
  end

  after do
    Ohai.config[:hints_path] = @original_hints
  end

  when_plugins_directory "doesn't contain any hints" do
    before do
      Ohai.config[:hints_path] = [ path_to(".") ]
    end

    it "hint? should return nil" do
      expect(Ohai::Hints.hint?("cloud")).to be_nil
    end
  end

  when_plugins_directory "contains empty and full hints" do
    with_plugin("cloud.json", <<EOF)
{"name":"circus"}
EOF

    with_plugin("cloud_empty.json", <<EOF)
EOF

    before do
      Ohai.config[:hints_path] = [ path_to(".") ]
    end

    it "hint? should return the data for full hints" do
      expect(Ohai::Hints.hint?("cloud")).to eq({ "name" => "circus" })
    end

    it "hint? should return empty hash for empty hints" do
      expect(Ohai::Hints.hint?("cloud_empty")).to eq({})
    end
  end

end
