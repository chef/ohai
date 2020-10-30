# frozen_string_literal: true
$stderr.puts "WARN: Ohai::Util::FileHelper is deprecated, please use Ohai::Mixin::Which or remove if the reference is unnecessary"
require_relative "../mixin/which"
module Ohai::Util
  FileHelper = Ohai::Mixin::Which
end
