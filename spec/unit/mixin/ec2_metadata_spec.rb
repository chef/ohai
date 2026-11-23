#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
# WITHOUT WARRANTIES OR CONDIT"Net::HTTP Response"NS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require "spec_helper"
require "ohai/mixin/ec2_metadata"

describe Ohai::Mixin::Ec2Metadata do
  let(:mixin) do
    metadata_object = Object.new.extend(described_class)
    http_client = double("Net::HTTP client", read_timeout: 10, :read_timeout= => nil)
    allow(http_client).to receive(:put) { double("Net::HTTP::PUT Response", body: "AQAEAE4UUd-3NE5EEeYYXKxicVfDOHsx0YSHFFSuCvo2GfCcxzJsvg==", code: "200") }
    allow(http_client).to receive(:get).and_return(response)
    allow(metadata_object).to receive(:http_client).and_return(http_client)
    metadata_object
  end

  before do
    logger = instance_double("Mixlib::Log::Child", trace: nil, debug: nil, warn: nil)
    allow(mixin).to receive(:logger).and_return(logger)
  end

  describe "#best_api_version" do
    context "with a sorted list of metadata versions" do
      let(:response) { double("Net::HTTP Response", body: "1.0\n2011-05-01\n2012-01-12\nUnsupported", code: "200") }
      it "returns the most recent version" do
        expect(mixin.best_api_version).to eq("2012-01-12")
      end
    end

    context "with an unsorted list of metadata versions" do
      let(:response) { double("Net::HTTP Response", body: "1.0\n2009-04-04\n2007-03-01\n2011-05-01\n2008-09-01\nUnsupported", code: "200") }

      it "returns the most recent version (using string sort)" do
        expect(mixin.best_api_version).to eq("2011-05-01")
      end
    end

    context "with versions newer than Ohai's original list" do
      let(:response) { double("Net::HTTP Response", body: "2021-03-23\n2021-07-15\n2022-09-24\nlatest", code: "200") }

      it "returns the newest version the service lists" do
        expect(mixin.best_api_version).to eq("2022-09-24")
      end
    end

    context "when no supported versions are found" do
      let(:response) { double("Net::HTTP Response", body: "Unsupported\nlatest", code: "200") }

      it "raises an error" do
        expect { mixin.best_api_version }.to raise_error(RuntimeError)
      end
    end

    # Presume 'latest' when we get a 404 for Eucalyptus back-compat
    context "when the response code is 404" do
      let(:response) { double("Net::HTTP Response", code: "404") }

      it "returns 'latest' as the version" do
        expect(mixin.best_api_version).to eq("latest")
      end
    end

    context "when the response code is unexpected" do
      let(:response) { double("Net::HTTP Response", body: "1.0\n2011-05-01\n2012-01-12\nUnsupported", code: "418") }

      it "raises an error" do
        expect { mixin.best_api_version }.to raise_error(RuntimeError)
      end
    end

    context "when metadata service is disabled" do
      let(:response) { double("Net::HTTP::PUT Response", body: "403 - Forbidden", code: "403") }
      it "raises an error" do
        expect { mixin.best_api_version }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#metadata_get" do
    context "when the response code is unexpected" do
      let(:response) { double("Net::HTTP Response", body: "", code: "418") }

      it "skips the path instead of failing the run" do
        expect(mixin.logger).to receive(:warn).with(/418/)
        expect(mixin.metadata_get("", "2012-01-12")).to be_nil
      end
    end

    context "when the service is temporarily unavailable" do
      let(:response) { double("Net::HTTP Response", body: "", code: "503") }

      before { allow(mixin).to receive(:sleep) }

      it "retries and returns the value once it succeeds" do
        allow(mixin.http_client).to receive(:get).and_return(
          double("Net::HTTP Response", body: "", code: "503"),
          double("Net::HTTP Response", body: "ip-10-0-0-1.ec2.internal", code: "200")
        )
        expect(mixin.metadata_get("local-hostname", "2012-01-12")).to eq("ip-10-0-0-1.ec2.internal")
      end

      it "gives up on the path after three attempts" do
        expect(mixin.http_client).to receive(:get).exactly(3).times.and_return(response)
        expect(mixin.metadata_get("local-hostname", "2012-01-12")).to be_nil
      end
    end

    context "when the token is rejected" do
      let(:response) { double("Net::HTTP Response", body: "", code: "401") }

      it "fetches a new token and retries once" do
        expect(mixin.http_client).to receive(:put).twice.and_return(
          double("Net::HTTP::PUT Response", body: "old-token", code: "200"),
          double("Net::HTTP::PUT Response", body: "new-token", code: "200")
        )
        expect(mixin.http_client).to receive(:get)
          .with("/2012-01-12/meta-data/local-hostname", { 'X-aws-ec2-metadata-token': "old-token" })
          .and_return(response)
        expect(mixin.http_client).to receive(:get)
          .with("/2012-01-12/meta-data/local-hostname", { 'X-aws-ec2-metadata-token': "new-token" })
          .and_return(double("Net::HTTP Response", body: "ip-10-0-0-1.ec2.internal", code: "200"))
        expect(mixin.metadata_get("local-hostname", "2012-01-12")).to eq("ip-10-0-0-1.ec2.internal")
      end
    end

    context "with a tag key that isn't valid in a URL" do
      let(:response) { double("Net::HTTP Response", body: "critical", code: "200") }

      it "escapes it in the request path" do
        expect(mixin.http_client).to receive(:get)
          .with("/2012-01-12/meta-data/tags/instance/Patch%20Group", anything)
          .and_return(response)
        expect(mixin.metadata_get("tags/instance/Patch Group", "2012-01-12")).to eq("critical")
      end
    end
  end

  describe "#v2_token" do
    let(:response) { double("Net::HTTP Response", body: "", code: "200") }

    it "requests a token that lasts the whole run" do
      expect(mixin.http_client).to receive(:put)
        .with("/latest/api/token", nil, { 'X-aws-ec2-metadata-token-ttl-seconds': "21600" })
        .and_return(double("Net::HTTP::PUT Response", body: "token", code: "200"))
      expect(mixin.v2_token).to eq("token")
    end

    it "uses no token when the token request is refused" do
      allow(mixin.http_client).to receive(:put).and_return(double("Net::HTTP::PUT Response", body: "403 - Forbidden", code: "403"))
      expect(mixin.v2_token).to be_nil
    end

    it "uses no token when the token request times out" do
      allow(mixin.http_client).to receive(:put).and_raise(Net::ReadTimeout)
      expect(mixin.v2_token).to be_nil
    end

    it "shortens the read timeout for the token request and restores it" do
      expect(mixin.http_client).to receive(:read_timeout=).with(2).ordered
      expect(mixin.http_client).to receive(:put).ordered.and_return(double("Net::HTTP::PUT Response", body: "token", code: "200"))
      expect(mixin.http_client).to receive(:read_timeout=).with(10).ordered
      mixin.v2_token
    end

    it "asks only once when the service has no tokens" do
      expect(mixin.http_client).to receive(:put).once.and_return(double("Net::HTTP::PUT Response", body: "", code: "404"))
      2.times { expect(mixin.v2_token).to be_nil }
    end
  end

  describe "#best_api_version" do
    context "when the response code is 404" do
      let(:response) { double("Net::HTTP Response", code: "404") }

      it "asks only once" do
        expect(mixin.http_client).to receive(:get).once.and_return(response)
        2.times { expect(mixin.best_api_version).to eq("latest") }
      end
    end
  end

  describe "#expand_path" do
    let(:response) { double("Net::HTTP Response", body: "", code: "200") }

    it "turns a public-keys entry into its index directory" do
      expect(mixin.send(:expand_path, "public-keys/0=my-key")).to eq("public-keys/0/")
    end

    it "leaves other names containing '=' alone" do
      expect(mixin.send(:expand_path, "tags/instance/env=prod")).to eq("tags/instance/env=prod")
    end
  end
end
