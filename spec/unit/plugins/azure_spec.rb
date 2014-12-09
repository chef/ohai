#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright (c) 2011-2013 Opscode, Inc.
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
require 'open-uri'

describe Ohai::System, "plugin azure" do
  let (:fetched_metadata) {
    {
      'public_ipv4' => '1.2.3.4',
      'private_ipv4' => '192.168.0.1',
      'public_hostname' => 'public_hostname'
    }
  }

  before(:each) do
    @plugin = get_plugin('azure')
    allow(@plugin).to receive(:hint?).with('azure').and_return({})
    allow(@plugin).to receive(:fetch_azure_metadata).and_return(fetched_metadata)
    @plugin.run
  end

  # Provide only success scenario
  it 'populate azure node with required attributes' do
    expect(@plugin[:azure]).not_to be_nil
    expect(@plugin[:azure]).to eq(fetched_metadata)
  end
end
