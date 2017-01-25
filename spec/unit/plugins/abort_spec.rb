#
# Author:: Salim Alam (salam@chef.io)
# Copyright:: Copyright (c) 2015 Chef Software Inc.
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

tmp = ENV["TMPDIR"] || ENV["TMP"] || ENV["TEMP"] || "/tmp"

abortstr = <<EOF
Ohai.plugin(:Abort) do
  provides "abort_test"
  collect_data do
    abort
  end
end
EOF

describe "a plug-in that aborts execution" do
  before(:all) do
    begin
      Dir.mkdir("#{tmp}/plugins")
    rescue Errno::EEXIST
      # ignore
    end
  end

  before(:each) do
    fail_file = File.open("#{tmp}/plugins/abort.rb", "w+")
    fail_file.write(abortstr)
    fail_file.close
  end

  after(:each) do
    File.delete("#{tmp}/plugins/abort.rb")
  end

  after(:all) do
    begin
      Dir.delete("#{tmp}/plugins")
    rescue
      # ignore
    end
  end

  before(:each) do
    @ohai = Ohai::System.new
    @loader = Ohai::Loader.new(@ohai)
    @runner = Ohai::Runner.new(@ohai)
  end

  it "should raise SystemExit" do
    @plugin = @loader.load_plugin("#{tmp}/plugins/abort.rb")
    expect { @runner.run_plugin(@plugin) }.to raise_error(SystemExit)
  end
end
