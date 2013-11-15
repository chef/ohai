require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Ohai::System, "plugin ip_scopes" do
  let(:plugin) { get_plugin('ip_scopes') }
  let(:network) { Mash.new(:interfaces => interfaces) }
  let(:interfaces) { Hash[
      interface1, { :addresses => addresses1, :type => interface1_type },
      interface2, { :addresses => addresses2, :type => interface2_type }] }
  let(:interface1) { :eth0 }
  let(:interface2) { :eth1 }
  let(:addresses1) { {} }
  let(:addresses2) { {} }
  let(:interface1_type) { 'eth' }
  let(:interface2_type) { 'eth' }

  before { plugin[:network] = network }

  context 'with ipaddr_extensions gem' do
    let(:ip1) { '10.0.0.1' }
    let(:ip2) { '1.2.3.4' }
    let(:ip3) { 'fe80::8638:35ff:fe4e:dc74' }

    let(:addresses1) { Hash[ip1, {}] }
    let(:addresses2) { Hash[ip2, {}, ip3, {}] }

    it 'adds ip_scope to each address' do
      plugin.run
      expect(plugin[:network][:interfaces][:eth0][:addresses]['10.0.0.1'][:ip_scope]).to eq('RFC1918 PRIVATE')
      expect(plugin[:network][:interfaces][:eth1][:addresses]['1.2.3.4'][:ip_scope]).to eq('GLOBAL UNICAST')
      expect(plugin[:network][:interfaces][:eth1][:addresses]['fe80::8638:35ff:fe4e:dc74'][:ip_scope]).to eq('LINK LOCAL UNICAST')
    end

    describe 'privateaddress' do
      before { plugin.run }

      context 'host has multiple RFC1918 ethernet addresses' do
        let(:ip1) { '10.0.0.1' }
        let(:ip2) { '192.168.1.1' }
        let(:interface1_type) { 'eth' }
        let(:interface2_type) { 'eth' }

        it 'picks the last address' do
          expect(plugin[:privateaddress]).to eq('192.168.1.1')
        end
      end

      context 'host has PPP and ethernet RFC1918 addresses' do
        let(:ip1) { '10.0.0.1' }
        let(:ip2) { '192.168.1.1' }
        let(:interface1_type) { 'eth' }
        let(:interface2_type) { 'ppp' }

        it 'prefers the eth address' do
          expect(plugin[:privateaddress]).to eq('10.0.0.1')
        end
      end

      context 'host only has ppp RFC1918 address' do
        let(:ip1) { '10.0.0.1' }
        let(:interface1_type) { 'ppp' }

        it 'uses it' do
          expect(plugin[:privateaddress]).to eq('10.0.0.1')
        end
      end
    end
  end

  context 'without the ipaddr_extensions gem' do
    let(:addresses1) { Hash['10.0.0.1', {}] }

    before do
      # standin for raising on `require 'ipaddr_extensions'`
      plugin[:network][:interfaces].stub(:keys).and_raise(LoadError)
      plugin.run
    end

    it 'does not add ip_scope to address' do
      expect(plugin[:network][:interfaces][:eth0][:addresses]['10.0.0.1'][:ip_scope]).to be nil
    end

    it 'does not add a privateaddress key' do
      expect(plugin[:privateaddress]).to be nil
    end
  end
end
