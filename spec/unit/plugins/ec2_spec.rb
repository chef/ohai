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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require 'open-uri'
require 'base64'

describe Ohai::System, "plugin ec2" do
  before(:each) do
    @plugin = get_plugin("ec2")
    @plugin[:network] = {:interfaces => {:eth0 => {} } }
    allow(File).to receive(:exist?).with('/etc/chef/ohai/hints/ec2.json').and_return(false)
    allow(File).to receive(:exist?).with('C:\chef\ohai\hints/ec2.json').and_return(false)
  end

  shared_examples_for "!ec2" do
    it "should NOT attempt to fetch the ec2 metadata" do
      expect(@plugin).not_to receive(:http_client)
      @plugin.run
    end
  end

  shared_examples_for "ec2" do
    before(:each) do
      @http_client = double("Net::HTTP client")
      allow(@plugin).to receive(:http_client).and_return(@http_client)
      allow(IO).to receive(:select).and_return([[],[1],[]])
      t = double("connection")
      allow(t).to receive(:connect_nonblock).and_raise(Errno::EINPROGRESS)
      allow(Socket).to receive(:new).and_return(t)
      expect(@http_client).to receive(:get).
        with("/").twice.
        and_return(double("Net::HTTP Response", :body => "2012-01-12", :code => "200"))
      allow(File).to receive(:exist?).and_return(false)
    end

    context "with common metadata paths" do
      let(:paths) do
        { "meta-data/" => "instance_type\nami_id\nsecurity-groups",
          "meta-data/instance_type" => "c1.medium",
          "meta-data/ami_id" => "ami-5d2dc934",
         "meta-data/security-groups" => "group1\ngroup2"
        }
      end

      it "recursively fetches all the ec2 metadata" do
        paths.each do |name,body|
          expect(@http_client).to receive(:get).
            with("/2012-01-12/#{name}").
            and_return(double("Net::HTTP Response", :body => body, :code => "200"))
        end
        expect(@http_client).to receive(:get).
          with("/2012-01-12/user-data/").
          and_return(double("Net::HTTP Response", :body => "By the pricking of my thumb...", :code => "200"))

        @plugin.run

        expect(@plugin[:ec2]).not_to be_nil
        expect(@plugin[:ec2]['instance_type']).to eq("c1.medium")
        expect(@plugin[:ec2]['ami_id']).to eq("ami-5d2dc934")
        expect(@plugin[:ec2]['security_groups']).to eql ['group1', 'group2']
      end

      it "fetches binary userdata opaquely" do
        paths.each do |name,body|
          expect(@http_client).to receive(:get).
            with("/2012-01-12/#{name}").
            and_return(double("Net::HTTP Response", :body => body, :code => "200"))
        end
        expect(@http_client).to receive(:get).
          with("/2012-01-12/user-data/").
          and_return(double("Net::HTTP Response", :body => "^_<8B>^H^H<C7>U^@^Csomething^@KT<C8><C9>,)<C9>IU(I-.I<CB><CC>I<E5>^B^@^Qz<BF><B0>^R^@^@^@", :code => "200"))

        @plugin.run

        expect(@plugin[:ec2]).not_to be_nil
        expect(@plugin[:ec2]['instance_type']).to eq("c1.medium")
        expect(@plugin[:ec2]['ami_id']).to eq("ami-5d2dc934")
        expect(@plugin[:ec2]['security_groups']).to eql ['group1', 'group2']
        expect(@plugin[:ec2]['userdata']).to eq(Base64.decode64("Xl88OEI+XkheSDxDNz5VXkBeQ3NvbWV0aGluZ15AS1Q8Qzg+PEM5PiwpPEM5\nPklVKEktLkk8Q0I+PENDPkk8RTU+XkJeQF5RejxCRj48QjA+XlJeQF5AXkA="))
      end
    end

    it "should parse ec2 network/ directory as a multi-level hash" do
      expect(@http_client).to receive(:get).
        with("/2012-01-12/meta-data/").
        and_return(double("Net::HTTP Response", :body => "network/", :code => "200"))
      expect(@http_client).to receive(:get).
        with("/2012-01-12/meta-data/network/").
        and_return(double("Net::HTTP Response", :body => "interfaces/", :code => "200"))
      expect(@http_client).to receive(:get).
        with("/2012-01-12/meta-data/network/interfaces/").
        and_return(double("Net::HTTP Response", :body => "macs/", :code => "200"))
      expect(@http_client).to receive(:get).
        with("/2012-01-12/meta-data/network/interfaces/macs/").
        and_return(double("Net::HTTP Response", :body => "12:34:56:78:9a:bc/", :code => "200"))
      expect(@http_client).to receive(:get).
        with("/2012-01-12/meta-data/network/interfaces/macs/12:34:56:78:9a:bc/").
        and_return(double("Net::HTTP Response", :body => "public_hostname", :code => "200"))
      expect(@http_client).to receive(:get).
        with("/2012-01-12/meta-data/network/interfaces/macs/12:34:56:78:9a:bc/public_hostname").
        and_return(double("Net::HTTP Response", :body => "server17.opscode.com", :code => "200"))
      expect(@http_client).to receive(:get).
        with("/2012-01-12/user-data/").
        and_return(double("Net::HTTP Response", :body => "By the pricking of my thumb...", :code => "200"))

      @plugin.run

      expect(@plugin[:ec2]).not_to be_nil
      expect(@plugin[:ec2]['network_interfaces_macs']['12:34:56:78:9a:bc']['public_hostname']).to eql('server17.opscode.com')
    end # context with common metadata paths

    context "with ec2_iam cloud file" do
      before do
        if windows?
          allow(File).to receive(:exist?).with('C:\chef\ohai\hints/iam.json').and_return(true)
          allow(File).to receive(:read).with('C:\chef\ohai\hints/iam.json').and_return('')
        else
          allow(File).to receive(:exist?).with('/etc/chef/ohai/hints/iam.json').and_return(true)
          allow(File).to receive(:read).with('/etc/chef/ohai/hints/iam.json').and_return('')
        end
      end

      it "should parse ec2 iam/ directory and collect iam/security-credentials/" do
        expect(@http_client).to receive(:get).
          with("/2012-01-12/meta-data/").
          and_return(double("Net::HTTP Response", :body => "iam/", :code => "200"))
        expect(@http_client).to receive(:get).
          with("/2012-01-12/meta-data/iam/").
          and_return(double("Net::HTTP Response", :body => "security-credentials/", :code => "200"))
        expect(@http_client).to receive(:get).
          with("/2012-01-12/meta-data/iam/security-credentials/").
          and_return(double("Net::HTTP Response", :body => "MyRole", :code => "200"))
        expect(@http_client).to receive(:get).
          with("/2012-01-12/meta-data/iam/security-credentials/MyRole").
          and_return(double("Net::HTTP Response", :body => "{\n  \"Code\" : \"Success\",\n  \"LastUpdated\" : \"2012-08-22T07:47:22Z\",\n  \"Type\" : \"AWS-HMAC\",\n  \"AccessKeyId\" : \"AAAAAAAA\",\n  \"SecretAccessKey\" : \"SSSSSSSS\",\n  \"Token\" : \"12345678\",\n  \"Expiration\" : \"2012-08-22T11:25:52Z\"\n}", :code => "200"))
        expect(@http_client).to receive(:get).
          with("/2012-01-12/user-data/").
          and_return(double("Net::HTTP Response", :body => "By the pricking of my thumb...", :code => "200"))

        @plugin.run

        expect(@plugin[:ec2]).not_to be_nil
        expect(@plugin[:ec2]['iam']['security-credentials']['MyRole']['Code']).to eql 'Success'
        expect(@plugin[:ec2]['iam']['security-credentials']['MyRole']['Token']).to eql '12345678'
      end
    end

    context "without ec2_iam cloud file" do
      before do
        if windows?
          allow(File).to receive(:exist?).with('C:\chef\ohai\hints/iam.json').and_return(false)
        else
          allow(File).to receive(:exist?).with('/etc/chef/ohai/hints/iam.json').and_return(false)
        end
      end

      it "should parse ec2 iam/ directory and NOT collect iam/security-credentials/" do
        expect(@http_client).to receive(:get).
          with("/2012-01-12/meta-data/").
          and_return(double("Net::HTTP Response", :body => "iam/", :code => "200"))
        expect(@http_client).to receive(:get).
          with("/2012-01-12/meta-data/iam/").
          and_return(double("Net::HTTP Response", :body => "security-credentials/", :code => "200"))
        expect(@http_client).to receive(:get).
          with("/2012-01-12/meta-data/iam/security-credentials/").
          and_return(double("Net::HTTP Response", :body => "MyRole", :code => "200"))
        expect(@http_client).to receive(:get).
          with("/2012-01-12/meta-data/iam/security-credentials/MyRole").
          and_return(double("Net::HTTP Response", :body => "{\n  \"Code\" : \"Success\",\n  \"LastUpdated\" : \"2012-08-22T07:47:22Z\",\n  \"Type\" : \"AWS-HMAC\",\n  \"AccessKeyId\" : \"AAAAAAAA\",\n  \"SecretAccessKey\" : \"SSSSSSSS\",\n  \"Token\" : \"12345678\",\n  \"Expiration\" : \"2012-08-22T11:25:52Z\"\n}", :code => "200"))
        expect(@http_client).to receive(:get).
          with("/2012-01-12/user-data/").
          and_return(double("Net::HTTP Response", :body => "By the pricking of my thumb...", :code => "200"))

        @plugin.run

        expect(@plugin[:ec2]).not_to be_nil
        expect(@plugin[:ec2]['iam']).to be_nil
      end
    end

    it "should ignore \"./\" and \"../\" on ec2 metadata paths to avoid infinity loops" do
      expect(@http_client).to receive(:get).
        with("/2012-01-12/meta-data/").
        and_return(double("Net::HTTP Response", :body => ".\n./\n..\n../\npath1/.\npath2/./\npath3/..\npath4/../", :code => "200"))

      expect(@http_client).not_to receive(:get).
        with("/2012-01-12/meta-data/.")
      expect(@http_client).not_to receive(:get).
        with("/2012-01-12/meta-data/./")
      expect(@http_client).not_to receive(:get).
        with("/2012-01-12/meta-data/..")
      expect(@http_client).not_to receive(:get).
        with("/2012-01-12/meta-data/../")
      expect(@http_client).not_to receive(:get).
        with("/2012-01-12/meta-data/path1/..")

      expect(@http_client).to receive(:get).
        with("/2012-01-12/meta-data/path1/").
        and_return(double("Net::HTTP Response", :body => "", :code => "200"))
      expect(@http_client).to receive(:get).
        with("/2012-01-12/meta-data/path2/").
        and_return(double("Net::HTTP Response", :body => "", :code => "200"))
      expect(@http_client).to receive(:get).
        with("/2012-01-12/meta-data/path3/").
        and_return(double("Net::HTTP Response", :body => "", :code => "200"))
      expect(@http_client).to receive(:get).
        with("/2012-01-12/meta-data/path4/").
        and_return(double("Net::HTTP Response", :body => "", :code => "200"))
      expect(@http_client).to receive(:get).
        with("/2012-01-12/user-data/").
        and_return(double("Net::HTTP Response", :body => "By the pricking of my thumb...", :code => "200"))

      @plugin.run

      expect(@plugin[:ec2]).not_to be_nil
    end

    it "should complete the run despite unavailable metadata" do
      expect(@http_client).to receive(:get).
        with("/2012-01-12/meta-data/").
        and_return(double("Net::HTTP Response", :body => "metrics/", :code => "200"))
      expect(@http_client).to receive(:get).
        with("/2012-01-12/meta-data/metrics/").
        and_return(double("Net::HTTP Response", :body => "vhostmd", :code => "200"))
      expect(@http_client).to receive(:get).
        with("/2012-01-12/meta-data/metrics/vhostmd").
        and_return(double("Net::HTTP Response", :body => "", :code => "404"))
      expect(@http_client).to receive(:get).
        with("/2012-01-12/user-data/").
        and_return(double("Net::HTTP Response", :body => "By the pricking of my thumb...", :code => "200"))

      @plugin.run

      expect(@plugin[:ec2]).not_to be_nil
      expect(@plugin[:ec2]['metrics']).to be_nil
      expect(@plugin[:ec2]['metrics_vhostmd']).to be_nil
    end
  end # shared examples for ec2

  describe "without dmi, with xen mac, and metadata address connected" do
    before(:each) do
      allow(IO).to receive(:select).and_return([[],[1],[]])
      @plugin[:network][:interfaces][:eth0][:arp] = {"169.254.1.0"=>"fe:ff:ff:ff:ff:ff"}
    end

    it_should_behave_like "ec2"

    it "warns that the arp table method is deprecated" do
      expect(Ohai::Log).to receive(:warn).with(/will be removed/)
      @plugin.has_ec2_mac?
    end
  end


  describe "without ec2 mac and metadata address connected" do
    it_should_behave_like "!ec2"

    before(:each) do
      @plugin[:network][:interfaces][:eth0][:arp] = {"169.254.1.0"=>"00:50:56:c0:00:08"}
    end
  end

  describe "with ec2 dmi data" do
    it_should_behave_like "ec2"

    before(:each) do
      @plugin[:dmi] = { :bios => { :all_records => [  { :Version => "4.2.amazon" } ] } }
    end
  end

  describe "without ec2 dmi data" do
    it_should_behave_like "!ec2"

    before(:each) do
      @plugin[:dmi] = nil
    end
  end

  describe "with ec2 cloud file" do
    it_should_behave_like "ec2"

    before(:each) do
      if windows?
        expect(File).to receive(:exist?).with('C:\chef\ohai\hints/ec2.json').and_return(true)
        allow(File).to receive(:read).with('C:\chef\ohai\hints/ec2.json').and_return('')
      else
        expect(File).to receive(:exist?).with('/etc/chef/ohai/hints/ec2.json').and_return(true)
        allow(File).to receive(:read).with('/etc/chef/ohai/hints/ec2.json').and_return('')
      end
    end
  end

  describe "without cloud file" do
    it_should_behave_like "!ec2"

    before(:each) do
      allow(File).to receive(:exist?).with('/etc/chef/ohai/hints/ec2.json').and_return(false)
      allow(File).to receive(:exist?).with('C:\chef\ohai\hints/ec2.json').and_return(false)
    end
  end

  describe "with rackspace cloud file" do
    it_should_behave_like "!ec2"

    before(:each) do
      allow(File).to receive(:exist?).with('/etc/chef/ohai/hints/ec2.json').and_return(false)
      allow(File).to receive(:exist?).with('C:\chef\ohai\hints/ec2.json').and_return(false)

      allow(File).to receive(:exist?).with('/etc/chef/ohai/hints/rackspace.json').and_return(true)
      allow(File).to receive(:read).with('/etc/chef/ohai/hints/rackspace.json').and_return('')
      allow(File).to receive(:exist?).with('C:\chef\ohai\hints/rackspace.json').and_return(true)
      allow(File).to receive(:read).with('C:\chef\ohai\hints/rackspace.json').and_return('')
    end
  end

end
