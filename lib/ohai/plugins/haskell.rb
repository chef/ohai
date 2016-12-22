# Author:: Chris Dituri (<csdituri@gmail.com>)
# Copyright:: Copyright (c) 2016 Chris Dituri
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

Ohai.plugin(:Haskell) do

  provides "languages/haskell",
           "languages/haskell/ghc",
           "languages/haskell/ghci",
           "languages/haskell/cabal",
           "languages/haskell/stack"

  depends "languages"

  collect_data(:default) do
    haskell = Mash.new

    # Check for ghc
    begin
      so = shell_out("ghc --version")

      # Sample output:
      # The Glorious Glasgow Haskell Compilation System, version 7.6.3
      if so.exitstatus == 0
        haskell[:ghc] = Mash.new
        haskell[:ghc][:version] = so.stdout.split[-1]
        haskell[:ghc][:description] = so.stdout.chomp
      end
    rescue Ohai::Exceptions::Exec
      Ohai::Log.debug('Plugin Haskell: Could not shell_out "ghc --version". Skipping data')
    end

    # Check for ghci
    begin
      so = shell_out("ghci --version")

      # Sample output:
      # The Glorious Glasgow Haskell Compilation System, version 7.6.3
      if so.exitstatus == 0
        haskell[:ghci] = Mash.new
        haskell[:ghci][:version] = so.stdout.split[-1]
        haskell[:ghci][:description] = so.stdout.chomp
      end
    rescue Ohai::Exceptions::Exec
      Ohai::Log.debug('Plugin Haskell: Could not shell_out "ghci --version". Skipping data')
    end

    # Check for cabal
    begin
      so = shell_out("cabal --version")

      # Sample output:
      # cabal-install version 1.16.0.2
      # using version 1.16.0 of the Cabal library
      if so.exitstatus == 0
        haskell[:cabal] = Mash.new
        haskell[:cabal][:version] = so.stdout.split("\n")[0].split[-1]
        haskell[:cabal][:description] = so.stdout.split("\n")[0].chomp
      end
    rescue Ohai::Exceptions::Exec
      Ohai::Log.debug('Plugin Haskell: Could not shell_out "cabal --version". Skipping data')
    end

    # Check for stack
    begin
      so = shell_out("stack --version")

      # Sample output:
      # Version 1.1.0, Git revision 0e9430aad55841b5ff2c6c2851f0548c16bce7cf (3540 commits) x86_64 hpack-0.13.0
      # or
      # Version 1.2.0 x86_64 hpack-0.14.0
      if so.exitstatus == 0
        haskell[:stack] = Mash.new
        haskell[:stack][:version] = /Version ([^\s,]*)/.match(so.stdout)[1] rescue nil
        haskell[:stack][:description] = so.stdout.chomp
      end
    rescue Ohai::Exceptions::Exec
      Ohai::Log.debug('Plugin Haskell: Could not shell_out "stack --version". Skipping data')
    end

    languages[:haskell] = haskell unless haskell.empty?
  end
end
