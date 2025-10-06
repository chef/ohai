#
# Contributed by: Matthew Massey <matthewmassey@fb.com>
# Copyright © 2008-2025 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Ohai::System, "Linux tc plugin" do
  let(:plugin) { get_plugin("linux/tc") }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
  end

  it "populates tc if tc is found" do
    tc_out = <<-TC_OUT
        qdisc noqueue 0: dev lo root refcnt 2
        qdisc mq 1234: dev eth0 root
        qdisc fq 8001: dev eth0 parent 1234:4 limit 10000p flow_limit 100p buckets 2048 orphan_mask 1023 quantum 3028b initial_quantum 15140b low_rate_threshold 550Kbit refill_delay 40.0ms
        qdisc fq_codel 0: dev eth0 parent 1234:7 limit 10240p flows 1024 quantum 1514 target 5.0ms interval 100.0ms memory_limit 32Mb ecn
        qdisc fq_codel 0: dev eth0 parent 1234:5 limit 10240p flows 1024 quantum 1514 target 5.0ms interval 100.0ms memory_limit 32Mb ecn
        qdisc fq_codel 0: dev eth0 parent 1234:3 limit 10240p flows 1024 quantum 1514 target 5.0ms interval 100.0ms memory_limit 32Mb ecn
        qdisc fq_codel 0: dev eth0 parent 1234:1 limit 10240p flows 1024 quantum 1514 target 5.0ms interval 100.0ms memory_limit 32Mb ecn
        qdisc fq 8003: dev eth0 parent 1234:6 limit 10000p flow_limit 100p buckets 8192 orphan_mask 1023 quantum 3028b initial_quantum 15140b low_rate_threshold 550Kbit refill_delay 40.0ms
        qdisc fq 8002: dev eth0 parent 1234:2 limit 10000p flow_limit 100p buckets 4096 orphan_mask 1023 nopacing quantum 3028b initial_quantum 15140b low_rate_threshold 550Kbit refill_delay 40.0ms
        qdisc pfifo_fast 8004: dev eth0 parent 1234:8 bands 3 priomap 1 2 2 2 1 2 0 0 1 1 1 1 1 1 1 1
        qdisc clsact ffff: dev eth0 parent ffff:fff1
        garbage line, this won't parse and should not break anything
        dev eth99 garbage line but with a device name
        qdisc fq 1234: dev eth0 fq but with no parms
    TC_OUT
    allow(plugin).to receive(:which).with("tc").and_return("/sbin/tc")
    cmd = "/sbin/tc qdisc show"
    allow(plugin).to receive(:shell_out).with(cmd).and_return(mock_shell_out(0, tc_out, ""))
    plugin.run

    expect(plugin[:tc].to_hash).to eq({
      "qdisc" => {
        "lo" => {
          "qdiscs" => [
            {
              "type" => "noqueue",
              "parms" => {},
            },
          ],
        },
        "eth0" => {
          "qdiscs" => [
            {
              "type" => "mq",
              "parms" => {},
            },
            {
              "type" => "fq",
              "parms" => {
                "buckets" => 2048,
              },
            },
            {
              "type" => "fq_codel",
              "parms" => {},
            },
            {
              "type" => "fq_codel",
              "parms" => {},
            },
            {
              "type" => "fq_codel",
              "parms" => {},
            },
            {
              "type" => "fq_codel",
              "parms" => {},
            },
            {
              "type" => "fq",
              "parms" => {
                "buckets" => 8192,
              },
            },
            {
              "type" => "fq",
              "parms" => {
                "buckets" => 4096,
              },
            },
            {
              "type" => "pfifo_fast",
              "parms" => {},
            },
            {
              "type" => "clsact",
              "parms" => {},
            },
            {
              "type" => "fq",
              "parms" => {},
            },
          ],
        },
        "eth99" => {},
        },
    })
  end

  it "does not populate tc if tc is not found" do
    allow(plugin).to receive(:which).with("tc").and_return(false)
    plugin.run
    expect(plugin[:tc]).to be(nil)
  end
end
