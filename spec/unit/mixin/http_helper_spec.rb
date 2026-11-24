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
require "ohai/mixin/http_helper"

describe Ohai::Mixin::HttpHelper do
  let(:mixin) do
    Object.new.tap do |o|
      o.extend(described_class)
      o.define_singleton_method(:logger) { Ohai::Log }
    end
  end

  # real loopback sockets, so these need no network access
  describe "#can_socket_connect?" do
    it "returns true when something is listening" do
      server = TCPServer.new("127.0.0.1", 0)
      expect(mixin.can_socket_connect?("127.0.0.1", server.addr[1])).to be true
    ensure
      server&.close
    end

    it "returns false when the connection is refused" do
      server = TCPServer.new("127.0.0.1", 0)
      port = server.addr[1]
      server.close

      expect(mixin.can_socket_connect?("127.0.0.1", port)).to be false
    end

    it "connects to an IPv6 address" do
      server = begin
                 TCPServer.new("::1", 0)
               rescue SystemCallError
                 skip "IPv6 loopback is unavailable"
               end
      expect(mixin.can_socket_connect?("::1", server.addr[1])).to be true
    ensure
      server&.close
    end

    it "returns false when the name doesn't resolve" do
      allow(Socket).to receive(:pack_sockaddr_in).and_raise(SocketError)
      expect(mixin.can_socket_connect?("metadata.invalid.", 80)).to be false
    end

    it "closes the socket it opens" do
      server = TCPServer.new("127.0.0.1", 0)
      sockets = []
      allow(Socket).to(receive(:new).and_wrap_original { |m, *args| m.call(*args).tap { |s| sockets << s } })

      mixin.can_socket_connect?("127.0.0.1", server.addr[1])
      expect(sockets.map(&:closed?)).to eq([true])
    ensure
      server&.close
    end
  end
end
