#
# Author:: Benjamin Black (<nostromo@gmail.com>)
# Author:: Daniel DeLeo <dan@kallistec.com>
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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
require 'socket'

provides "hostname", "fqdn"

hostname from("hostname")

fqdn_lookup = Socket.getaddrinfo(hostname, nil, nil, nil, nil, Socket::AI_CANONNAME).first[2]

if fqdn_lookup.split('.').length > 1
  # we recieved an fqdn
  fqdn fqdn_lookup
else
  # default to assembling one
  fqdn(from("hostname") + "." + from("domainname"))
end
