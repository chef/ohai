#
# Author:: Toomas Pelberg (toomas.pelberg@playtech.com>)
# Author:: Claire McQuin (claire@chef.io)
# Copyright:: Copyright (c) 2011, 2013-2016 Chef Software, Inc.
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

tmp = ENV["TMPDIR"] || ENV["TMP"] || ENV["TEMP"] || "/tmp"

shared_examples "a v7 loading failure" do
  before(:all) do

    Dir.mkdir("#{tmp}/plugins")
  rescue Errno::EEXIST
      # ignore

  end

  before do
    fail_file = File.open("#{tmp}/plugins/fail.rb", "w+")
    fail_file.write(failstr)
    fail_file.close
  end

  after do
    File.delete("#{tmp}/plugins/fail.rb")
  end

  after(:all) do

    Dir.delete("#{tmp}/plugins")
  rescue
      # ignore

  end

  before do
    @ohai = Ohai::System.new
    @loader = Ohai::Loader.new(@ohai)
  end

  it "does not have attribute keys" do
    @loader.load_plugin("#{tmp}/plugins/fail.rb")
    # @ohai.attributes.should_not have_key("fail")
    expect { @ohai.provides_map.find_providers_for(["fail"]) }.to raise_error(Ohai::Exceptions::AttributeNotFound)
  end

  it "writes to Ohai::Log" do
    expect(@loader.logger).to receive(:warn).once
    @loader.load_plugin("#{tmp}/plugins/fail.rb")
  end
end

shared_examples "a v7 loading success" do
  before(:all) do

    Dir.mkdir("#{tmp}/plugins")
  rescue Errno::EEXIST
      # ignore

  end

  before do
    fail_file = File.open("#{tmp}/plugins/fail.rb", "w+")
    fail_file.write(failstr)
    fail_file.close
  end

  after do
    File.delete("#{tmp}/plugins/fail.rb")
  end

  after(:all) do

    Dir.delete("#{tmp}/plugins")
  rescue
      # ignore

  end

  before do
    @ohai = Ohai::System.new
    @loader = Ohai::Loader.new(@ohai)
  end

  it "has attribute keys" do
    @loader.load_plugin("#{tmp}/plugins/fail.rb")
    expect(@ohai.provides_map).to have_key("fail")
  end

  it "does not write to Ohai::Log" do
    expect(@loader.logger).not_to receive(:warn)
    @loader.load_plugin("#{tmp}/plugins/fail.rb")
  end
end

shared_examples "a v7 run failure" do
  before(:all) do

    Dir.mkdir("#{tmp}/plugins")
  rescue Errno::EEXIST
      # ignore

  end

  before do
    fail_file = File.open("#{tmp}/plugins/fail.rb", "w+")
    fail_file.write(failstr)
    fail_file.close
  end

  after do
    File.delete("#{tmp}/plugins/fail.rb")
  end

  after(:all) do

    Dir.delete("#{tmp}/plugins")
  rescue
      # ignore

  end

  before do
    @ohai = Ohai::System.new
    @loader = Ohai::Loader.new(@ohai)
  end

  it "does not have new attribute keys" do
    @loader.load_plugin("#{tmp}/plugins/fail.rb").new(@ohai).run
    expect(@ohai.provides_map).not_to have_key("other")
  end

  it "writes to Ohai::Log" do
    expect(@loader.logger).to receive(:warn).once
    @loader.load_plugin("#{tmp}/plugins/fail.rb").new(@ohai).run
  end
end

describe "when using DSL commands outside Ohai.plugin block" do
  failstr1 = <<~EOF
    provides "fail"
    Ohai.plugin do
    end
  EOF

  failstr2 = <<~EOF
    depends "fail"
    Ohai.plugin do
    end
  EOF

  failstr3 = <<~EOF
    collect_data do
    end
    Ohai.plugin do
    end
  EOF

  it_behaves_like "a v7 loading failure" do
    let(:failstr) { failstr1 }
  end

  it_behaves_like "a v7 loading failure" do
    let(:failstr) { failstr2 }
  end

  it_behaves_like "a v7 loading failure" do
    let(:failstr) { failstr3 }
  end
end

describe "when using nonexistent DSL commands in Ohai.plugin block" do
  failstr = "Ohai.plugin do\n\tcreates \"fail\"\nend\n"

  it_behaves_like "a v7 loading failure" do
    let(:failstr) { failstr }
  end
end

=begin
describe "when using DSL commands in collect_data block" do
  failstr1 = <<EOF
Ohai.plugin do
  provides "fail"
  collect_data do
    provides "other"
  end
end
EOF

  failstr2 =<<EOF
Ohai.plugin do
  provides "fail"
  collect_data do
    provides "other"
  end
end
EOF

  it_behaves_like "a v7 loading success" do
    let(:failstr) { failstr1 }
  end

  it_behaves_like "a v7 run failure" do
    let(:failstr) { failstr1 }
  end

  it_behaves_like "a v7 loading success" do
    let(:failstr) { failstr2 }
  end

  it_behaves_like "a v7 run failure" do
    let(:failstr) { failstr2 }
  end
end

describe "when setting undeclared attribute in collect_data block" do
  failstr = <<EOF
Ohai.plugin do
  provides "fail"
  collect_data do
    creates "other"
  end
end
EOF
  it_behaves_like "a v7 loading success" do
    let(:failstr) { failstr }
  end

  it_behaves_like "a v7 run failure" do
    let(:failstr) { failstr }
  end
end

describe "when setting undeclared attribute" do
  failstr = <<EOF
provides "fail"
other "attribute"
EOF

  it_behaves_like "a v6 run failure" do
    let(:failstr) { failstr }
  end
end
=end
