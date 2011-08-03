require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
passwd_plugin_path=Ohai::Config[:plugin_path].first+"/passwd.rb"

describe Ohai::System, "plugin passwd from files" do
  before(:each) do
    Ohai::Log.level=:debug
    @ohai = Ohai::System.new
    @ohai.stub!(:require_plugin).and_return(true)
    File.should_receive(:exists?).with(passwd_plugin_path).and_return(true)
    File.should_receive(:exists?).with("/etc/passwd").and_return(true)
    File.should_receive(:exists?).with("/etc/group").and_return(true)
    File.should_receive(:readlines).with("/etc/passwd").once.and_return(["root:x:0:0:BOFH:/root:/bin/zsh","www:x:800:800:Serving the web since 1970:/var/www:/bin/false"])
    File.should_receive(:readlines).with("/etc/group").once.and_return(["admin:x:100:root,chef","www:x:800:www,deploy"])
  end
  
  it "should include a list of all users from /etc/passwd" do
    @ohai._require_plugin("passwd")
    @ohai[:etc][:passwd]['root'].should == Mash.new(:shell => '/bin/zsh', :gecos => 'BOFH', :gid => 0, :uid => 0, :dir => '/root')
    @ohai[:etc][:passwd]['www'].should == Mash.new(:shell => '/bin/false', :gecos => 'Serving the web since 1970', :gid => 800, :uid => 800, :dir => '/var/www')
  end
    
  it "should set the available groups from /etc/group" do
    @ohai._require_plugin("passwd")
    @ohai[:etc][:group]['admin'].should == Mash.new(:gid => 100, :members => ['root', 'chef'])
    @ohai[:etc][:group]['www'].should == Mash.new(:gid => 800, :members => ['www', 'deploy'])
  end
  
  it "should set the current user" do
    Etc.should_receive(:getlogin).and_return('chef')
    @ohai._require_plugin("passwd")
    @ohai[:current_user].should == 'chef'
  end
  
end

describe Ohai::System, "plugin passwd from Etc" do
  before(:each) do
    @ohai = Ohai::System.new
    @ohai.stub!(:require_plugin).and_return(true)
    File.should_receive(:exists?).with(passwd_plugin_path).and_return(true)
    File.should_receive(:exists?).with("/etc/passwd").and_return(false)
  end
  
  PasswdEntry = Struct.new(:name, :uid, :gid, :dir, :shell, :gecos)
  GroupEntry = Struct.new(:name, :gid, :mem)
  
  it "should include a list of all users from Etc" do
    Etc.should_receive(:passwd).and_yield(PasswdEntry.new("root", 1, 1, '/root', '/bin/zsh', 'BOFH')).
      and_yield(PasswdEntry.new('www', 800, 800, '/var/www', '/bin/false', 'Serving the web since 1970'))
    @ohai._require_plugin("passwd")
    @ohai[:etc][:passwd]['root'].should == Mash.new(:shell => '/bin/zsh', :gecos => 'BOFH', :gid => 1, :uid => 1, :dir => '/root')
    @ohai[:etc][:passwd]['www'].should == Mash.new(:shell => '/bin/false', :gecos => 'Serving the web since 1970', :gid => 800, :uid => 800, :dir => '/var/www')
  end
    
  it "should set the available groups from Etc" do
    Etc.should_receive(:group).and_yield(GroupEntry.new("admin", 100, ['root', 'chef'])).and_yield(GroupEntry.new('www', 800, ['www', 'deploy']))
    @ohai._require_plugin("passwd")
    @ohai[:etc][:group]['admin'].should == Mash.new(:gid => 100, :members => ['root', 'chef'])
    @ohai[:etc][:group]['www'].should == Mash.new(:gid => 800, :members => ['www', 'deploy'])
  end
  
  it "should set the current user" do
    Etc.should_receive(:getlogin).and_return('chef')
    @ohai._require_plugin("passwd")
    @ohai[:current_user].should == 'chef'
  end
  
end