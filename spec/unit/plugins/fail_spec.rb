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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "/spec_helper.rb"))

tmp = ENV["TMPDIR"] || ENV["TMP"] || ENV["TEMP"] || "/tmp"

shared_examples "a v7 loading failure" do
  before(:all) do
    begin
      Dir.mkdir("#{tmp}/plugins")
    rescue Errno::EEXIST
      # ignore
    end
  end

  before(:each) do
    fail_file = File.open("#{tmp}/plugins/fail.rb", "w+")
    fail_file.write(failstr)
    fail_file.close
  end

  after(:each) do
    File.delete("#{tmp}/plugins/fail.rb")
  end

  after(:all) do
    begin
      Dir.delete("#{tmp}/plugins")
    rescue
      # ignore
    end
  end

  before(:each) do
    @info_getter = info_getter::System.new
    @loader = info_getter::Loader.new(@info_getter)
  end

  it "should not have attribute keys" do
    @loader.load_plugin("#{tmp}/plugins/fail.rb")
    #@info_getter.attributes.should_not have_key("fail")
    expect { @info_getter.provides_map.find_providers_for(["fail"]) }.to raise_error(info_getter::Exceptions::AttributeNotFound)
  end

  it "should not have source key" do
    @loader.load_plugin("#{tmp}/plugins/fail.rb")
    expect(@info_getter.v6_dependency_solver).not_to have_key("#{tmp}/plugins/fail.rb")
  end

  it "should write to info_getter::Log" do
    expect(info_getter::Log).to receive(:warn).once
    @loader.load_plugin("#{tmp}/plugins/fail.rb")
  end
end

shared_examples "a v7 loading success" do
  before(:all) do
    begin
      Dir.mkdir("#{tmp}/plugins")
    rescue Errno::EEXIST
      # ignore
    end
  end

  before(:each) do
    fail_file = File.open("#{tmp}/plugins/fail.rb", "w+")
    fail_file.write(failstr)
    fail_file.close
  end

  after(:each) do
    File.delete("#{tmp}/plugins/fail.rb")
  end

  after(:all) do
    begin
      Dir.delete("#{tmp}/plugins")
    rescue
      # ignore
    end
  end

  before(:each) do
    @info_getter = info_getter::System.new
    @loader = info_getter::Loader.new(@info_getter)
  end

  it "should have attribute keys" do
    @loader.load_plugin("#{tmp}/plugins/fail.rb")
    expect(@info_getter.provides_map).to have_key("fail")
  end

  it "should have source key" do
    @loader.load_plugin("#{tmp}/plugins/fail.rb")
    expect(@info_getter.v6_dependency_solver).to have_key("#{tmp}/plugins/fail.rb")
  end

  it "should not write to info_getter::Log" do
    expect(info_getter::Log).not_to receive(:warn)
    @loader.load_plugin("#{tmp}/plugins/fail.rb")
  end
end

shared_examples "a v7 run failure" do
  before(:all) do
    begin
      Dir.mkdir("#{tmp}/plugins")
    rescue Errno::EEXIST
      # ignore
    end
  end

  before(:each) do
    fail_file = File.open("#{tmp}/plugins/fail.rb", "w+")
    fail_file.write(failstr)
    fail_file.close
  end

  after(:each) do
    File.delete("#{tmp}/plugins/fail.rb")
  end

  after(:all) do
    begin
      Dir.delete("#{tmp}/plugins")
    rescue
      # ignore
    end
  end

  before(:each) do
    @info_getter = info_getter::System.new
    @loader = info_getter::Loader.new(@info_getter)
  end

  it "should not have new attribute keys" do
    @loader.load_plugin("#{tmp}/plugins/fail.rb").new(@info_getter).run
    expect(@info_getter.provides_map).not_to have_key("other")
  end

  it "should write to info_getter::Log" do
    expect(info_getter::Log).to receive(:warn).once
    @loader.load_plugin("#{tmp}/plugins/fail.rb").new(@info_getter).run
  end
end

=begin
shared_examples "a v6 run failure" do
  before(:all) do
    begin
      Dir.mkdir("#{tmp}/plugins")
    rescue Errno::EEXIST
      # ignore
    end
  end

  before(:each) do
    fail_file = File.open("#{tmp}/plugins/fail.rb", "w+")
    fail_file.write(failstr)
    fail_file.close
  end

  after(:each) do
    File.delete("#{tmp}/plugins/fail.rb")
  end

  after(:all) do
    begin
      Dir.delete("#{tmp}/plugins")
    rescue
      # ignore
    end
  end

  before(:each) do
    @info_getter = info_getter::System.new
    @loader = info_getter::Loader.new(@info_getter)
  end

  it "should not add data keys" do
    @loader.load_plugin("#{tmp}/plugins/fail.rb")
    @info_getter.data.should_not have_key("fail")
  end

  it "should write to info_getter::Log" do
    info_getter::Log.should_receive(:warn).once
    @loader.load_plugin("#{tmp}/plugins/fail.rb").new(@info_getter).run
  end
end
=end

describe "when using DSL commands outside info_getter.plugin block" do
  failstr1 = <<EOF
provides "fail"
info_getter.plugin do
end
EOF

  failstr2 = <<EOF
depends "fail"
info_getter.plugin do
end
EOF

  failstr3 = <<EOF
collect_data do
end
info_getter.plugin do
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

describe "when using nonexistent DSL commands in info_getter.plugin block" do
  failstr = "info_getter.plugin do\n\tcreates \"fail\"\nend\n"

  it_behaves_like "a v7 loading failure" do
    let(:failstr) { failstr }
  end
end

=begin
describe "when using DSL commands in collect_data block" do
  failstr1 = <<EOF
info_getter.plugin do
  provides "fail"
  collect_data do
    provides "other"
  end
end
EOF

  failstr2 =<<EOF
info_getter.plugin do
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
info_getter.plugin do
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
