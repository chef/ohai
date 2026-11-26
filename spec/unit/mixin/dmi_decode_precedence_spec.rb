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
require "ohai/mixin/dmi_decode"

describe Ohai::Mixin::DmiDecode, "guest_from_dmi_data precedence" do
  let(:mixin) { Object.new.extend(described_class) }

  it "checks the manufacturer before the product" do
    expect(mixin.guest_from_dmi_data("OpenStack Foundation", "KVM", "15.1.5")).to eq("openstack")
  end

  # today's behavior; see #1997 and #2010
  it "raises NoMethodError for a Microsoft manufacturer with no product" do
    expect { mixin.guest_from_dmi_data("Microsoft Corporation", nil, nil) }.to raise_error(NoMethodError)
  end
end
