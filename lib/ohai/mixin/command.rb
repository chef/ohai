# frozen_string_literal: true
$stderr.puts "WARN: Ohai::Mixin::Command is deprecated, please use Ohai::Mixin::ShellOut or remove if the reference is unnecessary"
require_relative "shell_out"
Ohai::Mixin::Command = Ohai::Mixin::ShellOut unless defined?(Ohai::Mixin::Command)
