#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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


require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

ruby_bin = File.join(::Config::CONFIG['bindir'], ::Config::CONFIG['ruby_install_name'])

describe Ohai::System, "plugin ruby" do

  before(:all) do
    @ohai = Ohai::System.new
    @ohai[:languages] = Mash.new

    @ohai.require_plugin("ruby")

    @ruby_ohai_data_pristine = @ohai[:languages][:ruby]
  end

  before(:each) do
    @ruby_ohai_data = @ruby_ohai_data_pristine.dup
  end

  {
    :platform => RUBY_PLATFORM,
    :version => RUBY_VERSION,
    :release_date => RUBY_RELEASE_DATE,
    :target => ::Config::CONFIG['target'],
    :target_cpu => ::Config::CONFIG['target_cpu'],
    :target_vendor => ::Config::CONFIG['target_vendor'],
    :target_os => ::Config::CONFIG['target_os'],
    :host => ::Config::CONFIG['host'],
    :host_cpu => ::Config::CONFIG['host_cpu'],
    :host_os => ::Config::CONFIG['host_os'],
    :host_vendor => ::Config::CONFIG['host_vendor'],
    :gems_dir => %x{#{ruby_bin} #{::Config::CONFIG['bindir']}/gem env gemdir}.chomp!,
    :gem_bin => [ ::Gem.default_exec_format % 'gem', 'gem' ].map{|bin| "#{::Config::CONFIG['bindir']}/#{bin}"
      }.find{|bin| ::File.exists? bin},
    :ruby_bin => ruby_bin
  }.each do |attribute, value|
    it "should have #{attribute} set" do
      @ruby_ohai_data[attribute].should eql(value)
    end
  end
  
end
