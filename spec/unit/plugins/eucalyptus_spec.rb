#
# Author:: Tim Dysinger (<tim@dysinger.net>)
# Author:: Christopher Brown (cb@chef.io)
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
require "open-uri"

describe Ohai::System, "plugin eucalyptus" do
  let(:plugin) { get_plugin("eucalyptus") }

  shared_examples_for "!eucalyptus" do
    it "does NOT attempt to fetch the eucalyptus metadata" do
      expect(OpenURI).not_to receive(:open)
      plugin.run
    end
  end

  shared_examples_for "eucalyptus" do
    before(:each) do
      @http_client = double("Net::HTTP client")
      allow(plugin).to receive(:http_client).and_return(@http_client)

      expect(@http_client).to receive(:get).
        with("/").
        and_return(double("Net::HTTP Response", :body => "2012-01-12", :code => "200"))
      expect(@http_client).to receive(:get).
        with("/2012-01-12/meta-data/").
        and_return(double("Net::HTTP Response", :body => "instance_type\nami_id\nsecurity-groups", :code => "200"))
      expect(@http_client).to receive(:get).
        with("/2012-01-12/meta-data/instance_type").
        and_return(double("Net::HTTP Response", :body => "c1.medium", :code => "200"))
      expect(@http_client).to receive(:get).
        with("/2012-01-12/meta-data/ami_id").
        and_return(double("Net::HTTP Response", :body => "ami-5d2dc934", :code => "200"))
      expect(@http_client).to receive(:get).
        with("/2012-01-12/meta-data/security-groups").
        and_return(double("Net::HTTP Response", :body => "group1\ngroup2", :code => "200"))
      expect(@http_client).to receive(:get).
        with("/2012-01-12/user-data/").
        and_return(double("Net::HTTP Response", :body => "By the pricking of my thumb...", :code => "200"))
    end

    it "recursively fetches all the eucalyptus metadata" do
      allow(IO).to receive(:select).and_return([[], [1], []])
      t = double("connection")
      allow(t).to receive(:connect_nonblock).and_raise(Errno::EINPROGRESS)
      allow(Socket).to receive(:new).and_return(t)
      plugin.run
      expect(plugin[:eucalyptus]).not_to be_nil
      expect(plugin[:eucalyptus]["instance_type"]).to eq("c1.medium")
      expect(plugin[:eucalyptus]["ami_id"]).to eq("ami-5d2dc934")
      expect(plugin[:eucalyptus]["security_groups"]).to eql %w{group1 group2}
    end
  end

  describe "with eucalyptus mac and metadata address connected" do
    it_behaves_like "eucalyptus"

    before(:each) do
      allow(IO).to receive(:select).and_return([[], [1], []])
      plugin[:network] = { "interfaces" => { "eth0" => { "addresses" => { "d0:0d:95:47:6E:ED" => { "family" => "lladdr" } } } } }
    end
  end

  describe "without eucalyptus mac and metadata address connected" do
    it_behaves_like "!eucalyptus"

    before(:each) do
      plugin[:network] = { "interfaces" => { "eth0" => { "addresses" => { "ff:ff:95:47:6E:ED" => { "family" => "lladdr" } } } } }
    end
  end

  describe "with eucalyptus hint file" do
    it_behaves_like "eucalyptus"

    before(:each) do
      allow(plugin).to receive(:hint?).with("eucalyptus").and_return(true)
    end
  end

  describe "without hint file" do
    it_behaves_like "!eucalyptus"

    before(:each) do
      plugin[:network] = { :interfaces => {} }
      allow(plugin).to receive(:hint?).with("eucalyptus").and_return(false)
    end
  end

end
