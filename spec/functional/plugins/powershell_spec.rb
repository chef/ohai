#
# Copyright:: Copyright (c) 2014-2016 Chef Software, Inc.
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
#

require_relative "../../spec_helper.rb"

describe Ohai::System, "languages plugin" do
  VERSION_MATCHING_REGEX = /^(?:[\d]+\.)+[\d]+$/
  describe "powershell plugin", :windows_only do
    RSpec.shared_examples "a version looking thing" do
      it "should be present" do
        expect(subject).not_to be_nil
      end
      it "should look like a version" do
        expect(subject).to match(VERSION_MATCHING_REGEX)
      end
    end
    before(:all) do
      @plugin = get_plugin("powershell")
      @plugin[:languages] = Mash.new
      @plugin.run
    end

    subject { @plugin[:languages][:powershell] }

    it "should have information about powershell" do
      expect(subject).not_to be_nil
    end

    describe :version do
      subject { @plugin.languages[:powershell][described_class] }
      it_behaves_like "a version looking thing"
    end

    describe :ws_man_stack_version do
      subject { @plugin.languages[:powershell][described_class] }
      it_behaves_like "a version looking thing"
    end

    describe :serialization_version do
      subject { @plugin.languages[:powershell][described_class] }
      it_behaves_like "a version looking thing"
    end

    describe :clr_version do
      subject { @plugin.languages[:powershell][described_class] }
      it_behaves_like "a version looking thing"
    end

    describe :build_version do
      subject { @plugin.languages[:powershell][described_class] }
      it_behaves_like "a version looking thing"
    end

    describe :remoting_protocol_version do
      subject { @plugin.languages[:powershell][described_class] }
      it_behaves_like "a version looking thing"
    end

    describe :compatible_versions do
      it "has compatible_versions that look like versions" do
        @plugin.languages[:powershell][described_class].each do |version|
          expect(version).to match(VERSION_MATCHING_REGEX)
        end
      end
    end
  end
end
