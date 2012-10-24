require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Ohai::System, "plugin etc" do
  before(:each) do
    @ohai = Ohai::System.new
    @plugin = Ohai::DSL::Plugin.new(@ohai, File.join(PLUGIN_PATH, "passwd.rb"))
    @plugin.stub!(:require_plugin).and_return(true)
  end

  PasswdEntry = Struct.new(:name, :uid, :gid, :dir, :shell, :gecos)
  GroupEntry = Struct.new(:name, :gid, :mem)

  it "should include a list of all users" do
    Etc.should_receive(:passwd).and_yield(PasswdEntry.new("root", 1, 1, '/root', '/bin/zsh', 'BOFH')).
      and_yield(PasswdEntry.new('www', 800, 800, '/var/www', '/bin/false', 'Serving the web since 1970'))
    @plugin.run
    @plugin[:etc][:passwd]['root'].should == Mash.new(:shell => '/bin/zsh', :gecos => 'BOFH', :gid => 1, :uid => 1, :dir => '/root')
    @plugin[:etc][:passwd]['www'].should == Mash.new(:shell => '/bin/false', :gecos => 'Serving the web since 1970', :gid => 800, :uid => 800, :dir => '/var/www')
  end

  it "should set the current user" do
    Etc.should_receive(:getlogin).and_return('chef')
    @plugin.run
    @plugin[:current_user].should == 'chef'
  end

  it "should set the available groups" do
    Etc.should_receive(:group).and_yield(GroupEntry.new("admin", 100, ['root', 'chef'])).and_yield(GroupEntry.new('www', 800, ['www', 'deploy']))
    @plugin.run
    @plugin[:etc][:group]['admin'].should == Mash.new(:gid => 100, :members => ['root', 'chef'])
    @plugin[:etc][:group]['www'].should == Mash.new(:gid => 800, :members => ['www', 'deploy'])
  end

  if "".respond_to?(:force_encoding)
    it "sets the encoding of strings to the default external encoding" do
      fields = ["root", 1, 1, '/root', '/bin/zsh', 'BOFH']
      fields.each {|f| f.force_encoding(Encoding::ASCII_8BIT) if f.respond_to?(:force_encoding) }
      Etc.stub!(:passwd).and_yield(PasswdEntry.new(*fields))
      @plugin.run
      root = @plugin[:etc][:passwd]['root']
      root['gecos'].encoding.should == Encoding.default_external
    end
  end
end
