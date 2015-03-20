#
# Author:: Alexey Karpik <alexey.karpik@rightscale.com>
# Author:: Peter Schroeter <peter.schroeter@rightscale.com>
# Author:: Stas Turlo <stanislav.turlo@rightscale.com>
# Copyright:: Copyright (c) 2010-2014 RightScale Inc
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require 'ohai/mixin/azure_metadata'
require 'stringio'

describe ::Ohai::Mixin::AzureMetadata do
  let(:mixin) {
    mixin = Object.new.extend(::Ohai::Mixin::AzureMetadata)
    mixin
  }

  context 'fetch_azure_metadata' do
    it "should have specs"
  end

  context 'SharedConfig' do
    let (:public_ip) { "104.45.227.59" }
    let (:public_ssh_port) { 56111 }
    let (:service_name) { "a-459212403" }
    let (:instance_id) { "i-9476a0cdf" }
    let (:private_ip) { "10.100.0.5" }
    let (:shared_config) do
<<-eos
<?xml version="1.0" encoding="utf-8"?>
<SharedConfig version="1.0.0.0" goalStateIncarnation="1">
<Deployment name="e28face85b5a4b3fb9cb67f6be591fc6" guid="{f119102e-e3cd-44ff-b584-bf842389b43d}" incarnation="0">
  <Service name="#{service_name}" guid="{00000000-0000-0000-0000-000000000000}" />
  <ServiceInstance name="e28face85b5a4b3fb9cb67f6be591fc6.0" guid="{1453d7fb-0dd6-4953-bb60-da6b50b28927}" />
</Deployment>
<Incarnation number="1" instance="#{instance_id}" guid="{a4b9535d-6efe-4be3-b1bb-d46f953c59d1}" />
<Role guid="{81f1430c-7998-5f40-4961-a5f30ca0af2c}" name="#{instance_id}" settleTimeSeconds="0" />
<Instances>
  <Instance id="#{instance_id}" address="#{private_ip}">
    <FaultDomains randomId="0" updateId="0" updateCount="0" />
    <InputEndpoints>
      <Endpoint name="SSH" address="#{private_ip}:22" protocol="tcp" hostName="a-443655003ContractContract" isPublic="true" loadBalancedPublicAddress="#{public_ip}:#{public_ssh_port}" enableDirectServerReturn="false" isDirectAddress="false" disableStealthMode="false">
        <LocalPorts>
          <LocalPortRange from="22" to="22" />
        </LocalPorts>
      </Endpoint>
    </InputEndpoints>
  </Instance>
</Instances>
</SharedConfig>
eos
    end
    subject do
      ::Ohai::Mixin::AzureMetadata::SharedConfig.new shared_config
    end
    context "#service_name" do
      it 'should return service_name' do
        expect(service_name).to eq(service_name)
      end
    end

    context "#instance_id" do
      it 'should return instance_id' do
        expect(instance_id).to eq(instance_id)
      end
    end

    context "#private_ip" do
      it 'should return private_ip' do
        expect(private_ip).to eq(private_ip)
      end
    end

    context "#public_ip" do
      it 'should return public_ip' do
        expect(public_ip).to eq(public_ip)
      end
    end

    context "#public_ssh_port" do
      it 'should return public_ssh_port' do
        expect(public_ssh_port).to eq(public_ssh_port)
      end
    end
  end
end

