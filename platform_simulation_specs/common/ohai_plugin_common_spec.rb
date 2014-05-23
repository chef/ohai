
# Author:: Theodore Nordsieck <theo@opscode.com>
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

require File.expand_path(File.dirname(__FILE__) + "/ohai_plugin_common.rb")

describe OhaiPluginCommon, "subsumes?" do
  before(:each) do
    @hash = { "languages" => { "python" => { "version" => "1.6.2", "type" => "interpreted" }}}
  end

  it "returns true if given an exact duplicate" do
    subsumes?( @hash, @hash ).should be_true
  end

  it "returns false if given an exact duplicate with extra info" do
    subsumes?( @hash, { "languages" => { "python" => { "version" => "1.6.2", "os" => "darwin", "type" => "interpreted" }}} ).should be_false
    subsumes?( @hash, { "languages" => { "python" => { "version" => "1.6.2", "os" => {}, "type" => "interpreted" }}} ).should be_false
    subsumes?( @hash, { "languages" => { "python" => { "version" => "1.6.2", "os" => { "name" => "darwin" }, "type" => "interpreted" }}} ).should be_false
  end

  it "returns true if all elements in the second hash are in the first hash" do
    subsumes?( @hash, { "languages" => { "python" => { "version" => "1.6.2" }}} ).should be_true
    subsumes?( @hash, { "languages" => { "python" => {}}} ).should be_true
    subsumes?( @hash, { "languages" => {}} ).should be_true
  end

  it "returns true if the second hash contains a key pointing to a nil where the first hash has nothing" do
    subsumes?( @hash, { "languages" => { "lua" => nil }} ).should be_true
    subsumes?( @hash, { "languages" => { "python" => { "version" => "1.6.2" }, "lua" => nil }} ).should be_true
  end

  it "returns false if the second hash has nil in the place of a real value" do
    subsumes?( @hash, { "languages" => { "python" => { "version" => nil }}} ).should be_false
    subsumes?( @hash, { "languages" => { "python" => nil }} ).should be_false
    subsumes?( { "languages" => {}}, { "languages" => nil } ).should be_false
  end
end
