# encoding: utf-8
#
# Author:: Diego Algorta (diego@oboxodo.com)
# Copyright:: Copyright (c) 2009 Diego Algorta
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

describe Ohai::Mixin::Command, "popen4" do
  break if RUBY_PLATFORM =~ /(win|w)32$/

  it "should default all commands to be run in the POSIX standard C locale" do
    Ohai::Mixin::Command.popen4("echo $LC_ALL") do |pid, stdin, stdout, stderr|
      stdin.close
      stdout.read.strip.should == "C"
    end
  end

  it "should respect locale when specified explicitly" do
    Ohai::Mixin::Command.popen4("echo $LC_ALL", :environment => {"LC_ALL" => "es"}) do |pid, stdin, stdout, stderr|
      stdin.close
      stdout.read.strip.should == "es"
    end
  end

  if defined?(::Encoding) && "".respond_to?(:force_encoding) #i.e., ruby 1.9
    it "[OHAI-275] should mark strings as in the default external encoding" do
      extend Ohai::Mixin::Command
      snowy = run_command(:command => ("echo '" + ('☃' * 8096) + "'"))[1]
      snowy.encoding.should == Encoding.default_external
    end
  end

  it "reaps zombie processes after exec fails [OHAI-455]" do
    # NOTE: depending on ulimit settings, GC, etc., before the OHAI-455 patch,
    # ohai could also exhaust the available file descriptors when creating this
    # many zombie processes. A regression _could_ cause Errno::EMFILE but this
    # probably won't be consistent on different environments.
    created_procs = 0
    100.times do
      begin
        Ohai::Mixin::Command.popen4("/bin/this-is-not-a-real-command") {|p,i,o,e| nil }
      rescue Ohai::Exceptions::Exec
        created_procs += 1
      end
    end
    created_procs.should == 100
    reaped_procs = 0
    begin
      loop { Process.wait(-1); reaped_procs += 1 }
    rescue Errno::ECHILD
    end
    reaped_procs.should == 0
  end

end
