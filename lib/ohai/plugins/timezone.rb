# frozen_string_literal: true
#
# Author:: John Bellone (<jbellone@bloomberg.net>)
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Ohai.plugin(:Timezone) do
  provides "time/timezone"

  collect_data(:default) do
    time Mash.new unless time
    time[:timezone] = Time.now.getlocal.zone

    # Windows in German display language outputs LATIN1 bytes for .zone, but marks them as
    # IBM437, which somehow fails any attempt at conversion to other encodings when
    # ä is present, as in the timezone name "Mitteleuropäische Zeit" (Central Europe Time)
    #
    # Windows-1252 is the legacy encoding for Windows for German that actually
    # translates (ISO-8859-1 works as well), but going with the more correct
    # encoding name for Windows' implementation of Latin-1
    #
    # References
    # * [Code Page 437/IBM437](https://en.wikipedia.org/wiki/Code_page_437)
    # * [ISO/IEC 8859-1](https://en.wikipedia.org/wiki/ISO/IEC_8859-1)
    # * [Windows-1252](https://en.wikipedia.org/wiki/Windows-1252)
    if time[:timezone].encoding == Encoding::IBM437
      # Assume encoding is WINDOWS_1252
      time[:timezone] = time[:timezone].force_encoding(Encoding::WINDOWS_1252)
      # Re-encode in UTF_8. Note: If other encodings have problems converting
      # it might be worth re-encode everything in UTF_8.
      time[:timezone] = time[:timezone].encode(Encoding::UTF_8)
    end
  end
end
