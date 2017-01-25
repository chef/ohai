#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
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

ruby_bin = File.join(::RbConfig::CONFIG["bindir"], ::RbConfig::CONFIG["ruby_install_name"])

describe Ohai::System, "plugin ruby" do

  before(:all) do
    @plugin = get_plugin("ruby")
    @plugin[:languages] = Mash.new
    @plugin.run

    @ruby_ohai_data_pristine = @plugin[:languages][:ruby]
  end

  before(:each) do
    @ruby_ohai_data = @ruby_ohai_data_pristine.dup
  end

  {
    :platform => RUBY_PLATFORM,
    :version => RUBY_VERSION,
    :release_date => RUBY_RELEASE_DATE,
    :target => ::RbConfig::CONFIG["target"],
    :target_cpu => ::RbConfig::CONFIG["target_cpu"],
    :target_vendor => ::RbConfig::CONFIG["target_vendor"],
    :target_os => ::RbConfig::CONFIG["target_os"],
    :host => ::RbConfig::CONFIG["host"],
    :host_cpu => ::RbConfig::CONFIG["host_cpu"],
    :host_os => ::RbConfig::CONFIG["host_os"],
    :host_vendor => ::RbConfig::CONFIG["host_vendor"],
    :gems_dir => `#{ruby_bin} #{::RbConfig::CONFIG["bindir"]}/gem env gemdir`.chomp,
    :gem_bin => [ ::Gem.default_exec_format % "gem", "gem" ].map do |bin|
      "#{::RbConfig::CONFIG['bindir']}/#{bin}"
    end.find { |bin| ::File.exists? bin },
    :ruby_bin => ruby_bin,
  }.each do |attribute, value|
    it "should have #{attribute} set to #{value.inspect}" do
      expect(@ruby_ohai_data[attribute]).to eql(value)
    end
  end

end
