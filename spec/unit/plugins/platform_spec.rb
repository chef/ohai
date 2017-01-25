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

describe Ohai::System, "plugin platform" do
  before(:each) do
    @plugin = get_plugin("platform")
    allow(@plugin).to receive(:collect_os).and_return(:default)
    @plugin[:os] = "monkey"
    @plugin[:os_version] = "poop"
  end

  it "should set the platform and platform family to the os if it was not set earlier" do
    @plugin.run
    expect(@plugin[:platform]).to eql("monkey")
    expect(@plugin[:platform_family]).to eql("monkey")
  end

  it "should not set the platform to the os if it was set earlier" do
    @plugin[:platform] = "lars"
    @plugin.run
    expect(@plugin[:platform]).to eql("lars")
  end

  it "should set the platform_family to the platform if platform was set earlier but not platform_family" do
    @plugin[:platform] = "lars"
    @plugin[:platform_family] = "jack"
    @plugin.run
    expect(@plugin[:platform_family]).to eql("jack")
  end

  it "should not set the platform_family if the platform_family was set earlier." do
    @plugin[:platform] = "lars"
    @plugin.run
    expect(@plugin[:platform]).to eql("lars")
    expect(@plugin[:platform_family]).to eql("lars")
  end

  it "should set the platform_version to the os_version if it was not set earlier" do
    @plugin.run
    expect(@plugin[:os_version]).to eql("poop")
  end

  it "should not set the platform to the os if it was set earlier" do
    @plugin[:platform_version] = "ulrich"
    @plugin.run
    expect(@plugin[:platform_version]).to eql("ulrich")
  end
end
