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

require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper.rb")

describe Ohai::System, "plugin ohai_time" do
  before do
    @plugin = get_plugin("ohai_time")
  end

  it "gets the current time" do
    expect(Time).to receive(:now)
    @plugin.run
  end

  it "turns the time into a floating point number" do
    time = Time.now
    expect(time).to receive(:to_f)
    allow(Time).to receive(:now).and_return(time)
    @plugin.run
  end

  it "sets ohai_time to the current time" do
    time = Time.now
    allow(Time).to receive(:now).and_return(time)
    @plugin.run
    expect(@plugin[:ohai_time]).to eq(time.to_f)
  end
end
