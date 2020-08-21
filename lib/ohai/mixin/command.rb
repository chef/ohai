require_relative "shell_out"
Ohai::Mixin::Command = Ohai::Mixin::ShellOut unless defined?(Ohai::Mixin::Command)
