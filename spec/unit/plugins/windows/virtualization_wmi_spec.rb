# frozen_string_literal: true
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright (c) 2026 Tim Smith
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

require "spec_helper"

describe Ohai::System, "Windows virtualization without WMI data" do
  let(:plugin) { get_plugin("windows/virtualization") }
  let(:wmi) { double("WmiLite::Wmi") }

  before do
    allow(WmiLite::Wmi).to receive(:new).and_return(wmi)
    allow(plugin).to receive(:collect_os).and_return(:windows)
  end

  # today's behavior
  it "raises NoMethodError when Win32_ComputerSystemProduct returns nothing" do
    allow(wmi).to receive(:first_of).with("Win32_ComputerSystemProduct").and_return(nil)
    expect { plugin.run }.to raise_error(NoMethodError)
  end
end
