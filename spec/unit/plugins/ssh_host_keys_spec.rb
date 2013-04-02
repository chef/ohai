#
# Author:: Bryan McLellan <btm@opscode.com>
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '/spec_helper.rb'))

describe Ohai::System, "ssh_host_key plugin" do

  before(:each) do
    @ohai = Ohai::System.new
    @ohai[:keys] = Mash.new
    @ohai.stub(:require_plugin).and_return(true)

    # Avoid using the real from_file to load the plugin => less stubbing required
    @ohai.extend(SimpleFromFile)

    File.stub(:exists?).with("/etc/ssh/sshd_config").and_return(true)
    File.stub(:open).with("/etc/ssh/sshd_config").and_yield(sshd_config_file)
    File.stub(:exists?).and_return(true)
    File.stub(:exists?).with("/etc/ssh/ssh_host_dsa_key.pub").and_return(true)
    File.stub(:exists?).with("/etc/ssh/ssh_host_rsa_key.pub").and_return(true)
    File.stub(:exists?).with("/etc/ssh/ssh_host_ecdsa_key.pub").and_return(true)

    # Ensure we can still use IO.read
    io_read = IO.method(:read)
    IO.stub(:read) { |file| io_read.call(file) }

    # Return fake public key files so we don't have to go digging for them in unit tests
    @dsa_key = "ssh-dss AAAAB3NzaC1kc3MAAACBAMHlT02xN8kietxPfhcb98xHueTzKCOTz6dZlP/dmKILHrQOAExuSEeNiA2uvmhHNVQvs/cBsRiDxgSKux3ie2q8+MB6vHCiSpSkoPjrL75iT57YDilCB4/sytt6IJpj+H42wRDWTX0/QRybMHUvmnmEL0cwZXykSvrIum0BKB6hAAAAFQDsi6WUCClhtZIiTY9uh8eAre+SbQAAAIEAgNnuw0uEuqtcVif+AYd/bCZvL9FPqg7DrmTkamNEcVinhUGwsPGJTLJf+o5ens1X4RzQoi1R6Y6zCTL2FN/hZgINJNO0z9BN402wWrZmQd+Vb1U5DyDtveuvipqyQS+fm9neRwdLuv36Fc9f9nkZ7YHpkGPJp+yJpG4OoeREhwgAAACBAIf9kKLf2XiXnlByzlJ2Naa55d/hp2E059VKCRsBS++xFKYKvSqjnDQBFiMtAUhb8EdTyBGyalqOgqogDQVtwHfTZWZwqHAhry9aM06y92Eu/xSey4tWjKeknOsnRe640KC4zmKDBRTrjjkuAdrKPN9k3jl+OCc669JHlIfo6kqf oppa"
    @rsa_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAuhcVXV+nNapkyUC5p4TH1ymRxUjtMBKqYWmwyI29gVFnUNeHkKFHWon0KFeGJP2Rm8BfTiZa9ER9e8pRr4Nd+z1C1o0kVoxEEfB9tpSdTlpk1GG83D94l57fij8THRVIwuCEosViUlg1gDgC4SpxbqfdBkUN2qyf6JDOh7t2QpYh7berpDEWeBpb7BKdLEDT57uw7ijKzSNyaXqq8KkB9I+UFrRwpuos4W7ilX+PQ+mWLi2ZZJfTYZMxxVS+qJwiDtNxGCRwTOQZG03kI7eLBZG+igupr0uD4o6qeftPOr0kxgjoPU4nEKvYiGq8Rqd2vYrhiaJHLk9QB6xStQvS3Q== oppa"
    @ecdsa_key = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBx8VgvxmHxs/sIn/ATh0iUcuz1I2Xc0e1ejXCGHBMZ98IE3FBt1ezlqCpNMcHVV2skQQ8vyLbKxzweyZuNSDU8= oppa"
    IO.stub(:read).with("/etc/ssh/ssh_host_dsa_key.pub").and_return(@dsa_key)
    IO.stub(:read).with("/etc/ssh/ssh_host_rsa_key.pub").and_return(@rsa_key)
    IO.stub(:read).with("/etc/ssh/ssh_host_ecdsa_key.pub").and_return(@ecdsa_key)
  end

  shared_examples "loads keys" do
    it "reads the key and sets the dsa attribute correctly" do
      @ohai._require_plugin("ssh_host_key")
      @ohai[:keys][:ssh][:host_dsa_public].should eql(@dsa_key.split[1])
      @ohai[:keys][:ssh][:host_dsa_type].should be_nil
    end

    it "reads the key and sets the rsa attribute correctly" do
      @ohai._require_plugin("ssh_host_key")
      @ohai[:keys][:ssh][:host_rsa_public].should eql(@rsa_key.split[1])
      @ohai[:keys][:ssh][:host_rsa_type].should be_nil
    end

    it "reads the key and sets the ecdsa attribute correctly" do
      @ohai._require_plugin("ssh_host_key")
      @ohai[:keys][:ssh][:host_ecdsa_public].should eql(@ecdsa_key.split[1])
      @ohai[:keys][:ssh][:host_ecdsa_type].should eql(@ecdsa_key.split[0])
    end
  end

  context "when an sshd_config exists" do
    let :sshd_config_file do
      <<EOS
# HostKeys for protocol version 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
EOS
    end
    it_behaves_like "loads keys"
  end

  context "when an sshd_config exists with commented entries" do
    let :sshd_config_file do
      <<EOS
# HostKeys for protocol version 2
#HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_dsa_key
#HostKey /etc/ssh/ssh_host_ecdsa_key
EOS
    end
    it_behaves_like "loads keys"
  end

  context "when an sshd_config can not be found" do
    let :sshd_config_file do
      nil
    end
    before do
      File.stub(:exists?).with("/etc/ssh/sshd_config").and_return(false)
      File.stub(:exists?).with("/etc/sshd_config").and_return(false)
    end

    it_behaves_like "loads keys"
  end
end
