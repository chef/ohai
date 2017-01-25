#
#  Author:: Jennifer Marie Howard-Brown <jm.howardbrown@gmail.com>
#  License:: Apache License, Version 2.0
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

require_relative "../../../spec_helper.rb"

describe Ohai::System, "Linux Block Device Plugin" do
  DISKS = {
    "sda" => {
      "size" => "7814037168",
      "removable" => "0",
      "model" => "WDC WD4000F9YZ-0",
      "rev" => "1A01",
      "state" => "running",
      "timeout" => "30",
      "queue_depth" => "1",
      "vendor" => "ATA",
    },
    "dm-0" => {
      "size" => "7806976",
      "removable" => "0",
    },
  }

  def file_double(value)
    tmp_double = double
    expect(tmp_double).to receive(:read_nonblock).and_return(value)
    tmp_double
  end

  before(:each) do
    @plugin = get_plugin("linux/block_device")
    allow(@plugin).to receive(:collect_os).and_return(:linux)

    allow(File).to receive(:exists?).with("/sys/block").and_return(true)
    allow(Dir).to receive(:[]).with("/sys/block/*") do
      DISKS.collect { |disk, _files| "/sys/block/#{disk}" }
    end

    DISKS.each do |disk, checks|
      checks.each do |check, value|
        allow(File).to receive(:open).with(Regexp.new("#{disk}.*#{check}")).and_yield(file_double(value))
      end

      allow(File).to receive(:exists?).with(Regexp.new(disk)) do |arg|
        filepath = arg.split("/")
        checks[filepath.last].nil? ? false : true
      end

      allow(File).to receive(:basename) do |arg|
        arg.split("/").last
      end
    end
  end

  it "should collect all relevant data from disks" do
    @plugin.run
    DISKS.each do |disk, checks|
      expect(@plugin[:block_device][disk.to_sym]).to include(checks)
    end
  end
end
