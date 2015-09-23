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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Ohai::System, 'root_user' do
  before(:each) do
    @plugin = get_plugin('root_user')
    @plugin.run
  end

  describe 'with windows platform' do
    it 'should return the user system' do
      expect(@plugin[:root_user]).to eq('SYSTEM')
    end
  end

  describe 'with posix platform' do
    it 'should return the user root' do
      expect(@plugin[:root_user]).to eq('root')
    end
  end
end
