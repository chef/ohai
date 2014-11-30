# Author:: Krzysztof Wilczynski (<kwilczynski@chef.io>)
#
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
#
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

require 'spec_helper'
require 'ohai/util/socket_helper'

class SocketHelperMock
  include Ohai::Util::SocketHelper
end

describe 'Ohai::Util::SocketHelper' do
  let(:socket_helper) { SocketHelperMock.new }

  before(:each) do
    @socket = double('TCPSocket')
    allow(@socket).to receive(:close).and_return(nil)
    allow(Socket).to receive(:do_not_reverse_lookup).and_call_original
    allow(TCPSocket).to receive(:new).and_return(@socket)

    expect(Socket).to receive(:do_not_reverse_lookup).once
    expect(Socket).to receive(:do_not_reverse_lookup=).twice
  end

  describe 'when remote node is accessible' do
    it 'should return true when connection is accepted' do
      expect(TCPSocket).to receive(:new).with('chef.io', 42)
      expect(@socket).to receive(:close).once
      expect(socket_helper.tcp_port_open?('chef.io', 42)).to be true
    end
  end

  describe 'when remote node is not accessible' do
    it 'should return false when connection is refused' do
      allow(TCPSocket).to receive(:new).with('getchef.com', 80).and_raise(Errno::ECONNREFUSED)

      expect(TCPSocket).to receive(:new).with('getchef.com', 80)
      expect(@socket).not_to receive(:close)
      expect(socket_helper.tcp_port_open?('getchef.com', 80)).to be false
    end

    it 'should return false when connection cannot be established' do
      allow(TCPSocket).to receive(:new).with('opscode.com', 443).and_raise(Errno::EHOSTUNREACH)

      expect(TCPSocket).to receive(:new).with('opscode.com', 443)
      expect(@socket).not_to receive(:close)
      expect(socket_helper.tcp_port_open?('opscode.com', 443)).to be false
    end

    it 'should return false when it cannot resolve host name' do
      # The message can be (depending on version of Ruby and underlying libraries):
      #   SocketError: getaddrinfo: nodename nor servname provided, or not known
      #   SocketError: getaddrinfo: Name or service not known
      #   SocketError: getaddrinfo: No such host is known.
      #   SocketError: getaddrinfo: Temporary failure in name resolution
      allow(TCPSocket).to receive(:new).with('acme.com', 8080).and_raise(SocketError, 'getaddrinfo: Name or service not known')

      expect(TCPSocket).to receive(:new).with('acme.com', 8080)
      expect(@socket).not_to receive(:close)
      expect(socket_helper.tcp_port_open?('acme.com', 8080)).to be false
    end

    it 'should raise unknown SocketError exception' do
      allow(TCPSocket).to receive(:new).with('NCC-1701-D', 40759).and_raise(SocketError, 'the plasma conduit time-matter field appears to be removed')

      expect(TCPSocket).to receive(:new).with('NCC-1701-D', 40759)
      expect(@socket).not_to receive(:close)

      expect {
        socket_helper.tcp_port_open?('NCC-1701-D', 40759)
      }.to raise_error(SocketError) {|e|
        expect(e.message).to eq 'the plasma conduit time-matter field appears to be removed'
      }
    end

    it 'should return false when a timeout occurs' do
      allow(Timeout).to receive(:timeout).with(3).and_raise(Timeout::Error)

      expect(TCPSocket).not_to receive(:new).with('slow.net', 22)
      expect(@socket).not_to receive(:close)
      expect(socket_helper.tcp_port_open?('slow.net', 22, 3)).to be false
    end
  end
end
