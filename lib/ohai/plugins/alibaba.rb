# frozen_string_literal: true
#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

# How we detect Alibaba from easiest to hardest & least reliable
# 1. Ohai alibaba hint exists. This always works
# 2. DMI sys_vendor data mentions alibaba.

Ohai.plugin(:Alibaba) do
  require_relative "../mixin/alibaba_metadata"
  require_relative "../mixin/http_helper"

  include Ohai::Mixin::AlibabaMetadata
  include Ohai::Mixin::HttpHelper

  provides "alibaba"

  # look for alibaba string in dmi sys_vendor data within the sys tree.
  # this works even if the system lacks dmidecode use by the Dmi plugin
  # @return [Boolean] do we have Alibaba DMI data?
  def has_ali_dmi?
    if file_val_if_exists("/sys/class/dmi/id/sys_vendor").to_s.include?("Alibaba")
      logger.trace("Plugin Alibaba: has_ali_dmi? == true")
      true
    else
      logger.trace("Plugin Alibaba: has_ali_dmi? == false")
      false
    end
  end

  # return the contents of a file if the file exists
  # @param path[String] abs path to the file
  # @return [String] contents of the file if it exists
  def file_val_if_exists(path)
    if file_exist?(path)
      file_read(path)
    end
  end

  # a single check that combines all the various detection methods for Alibaba
  # @return [Boolean] Does the system appear to be on Alibaba
  def looks_like_alibaba?
    return true if hint?("alibaba") || has_ali_dmi?
  end

  collect_data do
    if looks_like_alibaba?
      logger.trace("Plugin Alibaba: looks_like_alibaba? == true")
      alibaba Mash.new
      fetch_metadata.each do |k, v|
        alibaba[k] = v
      end
    else
      logger.trace("Plugin Alibaba: looks_like_alibaba? == false")
      false
    end
  end
end
