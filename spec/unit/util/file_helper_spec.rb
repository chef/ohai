# Author:: Bryan McLellan <btm@loftninjas.org>
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

require_relative "../../spec_helper.rb"
require "ohai/util/file_helper"

class FileHelperMock
  include Ohai::Util::FileHelper
end

describe "Ohai::Util::FileHelper" do
  let(:file_helper) { FileHelperMock.new }

  before(:each) do
    allow(file_helper).to receive(:name).and_return("Fakeclass")
    allow(File).to receive(:executable?).and_return(false)
  end

  describe "which" do
    it "returns the path to an executable that is in the path" do
      allow(File).to receive(:executable?).with("/usr/bin/skyhawk").and_return(true)

      expect(file_helper.which("skyhawk")).to eql "/usr/bin/skyhawk"
    end

    it "returns false if the executable is not in the path" do
      expect(file_helper.which("the_cake")).to be false
    end
  end
end
