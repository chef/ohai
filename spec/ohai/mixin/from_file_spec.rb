#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
# License:: GNU GPL, Version 3
#
# Copyright (C) 2008, OpsCode Inc. 
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require File.join(File.dirname(__FILE__), '..', '..', '/spec_helper.rb')

describe Ohai::System, "from_file" do
  before(:each) do
    @ohai = Ohai::System.new
    File.stub!(:exists?).and_return(true)
    File.stub!(:readable?).and_return(true)
    IO.stub!(:read).and_return("king 'herod'")
  end
  
  it "should check to see that the file exists" do
    File.should_receive(:exists?).and_return(true)
    @ohai.from_file("/tmp/foo")
  end
  
  it "should check to see that the file is readable" do
    File.should_receive(:readable?).and_return(true)
    @ohai.from_file("/tmp/foo")
  end
  
  it "should actually read the file" do
    IO.should_receive(:read).and_return("king 'herod'")
    @ohai.from_file("/tmp/foo")
  end
  
  it "should call instance_eval with the contents of the file, file name, and line 1" do
    @ohai.should_receive(:instance_eval).with("king 'herod'", "/tmp/foo", 1)
    @ohai.from_file("/tmp/foo")
  end
  
  it "should raise an IOError if it cannot read the file" do
    File.stub!(:exists?).and_return(false)
    lambda { @ohai.from_file("/tmp/foo") }.should raise_error(IOError)
  end
end
