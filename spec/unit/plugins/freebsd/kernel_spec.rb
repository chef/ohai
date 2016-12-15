#
# Author:: Adam Jacob (<adam@chef.io>)
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

require File.expand_path(File.dirname(__FILE__) + "/../../../spec_helper.rb")

describe Ohai::System, "FreeBSD kernel plugin" do
  before do
    @plugin = get_plugin("kernel")
    allow(@plugin).to receive(:collect_os).and_return(:freebsd)
    allow(@plugin).to receive(:init_kernel).and_return({ :name => "freebsd" })
    allow(@plugin).to receive(:shell_out).with("uname -i").and_return(mock_shell_out(0, "foo\n", ""))
    allow(@plugin).to receive(:shell_out).with("sysctl kern.securelevel").and_return(mock_shell_out(0, "kern.securelevel: 1", ""))
    allow(@plugin).to receive(:shell_out).with( Ohai.abs_path( "/sbin/kldstat" )).and_return(mock_shell_out(0, "  1    7 0xc0400000 97f830   kernel", ""))
  end

  it "sets the kernel_os to the kernel_name value" do
    @plugin.run
    expect(@plugin[:kernel][:os]).to eq(@plugin[:kernel][:name])
  end

end
