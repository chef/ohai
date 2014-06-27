require 'spec_helper'


describe Ohai::System, "plugin joyent" do
  before(:each) do
    @plugin = get_plugin('joyent')
  end

  describe "without joyent" do
    before(:each) do
      @plugin.stub(:is_smartos?).and_return(false)
    end

    it "should NOT create joyent" do
      @plugin.run
      @plugin[:joyent].should be_nil
    end
  end

  describe "with joyent" do
    before(:each) do
      @plugin.stub(:is_smartos?).and_return(true)
      @plugin[:virtualization] = Mash.new
      @plugin[:virtualization][:guest_uuid] = "global"
    end

    it "should create joyent" do
      @plugin.run
      @plugin[:joyent].should_not be_nil
    end

    describe "under global zone" do
      before(:each) do
        @plugin.run
      end

      it "should ditect global zone" do
        @plugin[:joyent][:sm_uuid].should eql 'global'
      end

      it "should NOT create sm_id" do
        @plugin[:joyent][:sm_id].should be_nil
      end
    end

    describe "under smartmachine" do
      before(:each) do
        @plugin[:virtualization][:guest_uuid] = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx'
        @plugin[:virtualization][:guest_id] = '30'
        @plugin.stub(:collect_product_file).and_return(["Name: Joyent Instance", "Image: base64 13.4.2", "Documentation: http://wiki.joyent.com/jpc2/SmartMachine+Base"])
        @plugin.stub(:collect_pkgsrc).and_return('http://pkgsrc.joyent.com/packages/SmartOS/2013Q4/x86_64/All')
        @plugin.run
      end

      it "should retrive zone uuid" do
        @plugin[:joyent][:sm_uuid].should eql 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx'
      end

      it "should collect sm_id" do
        @plugin[:joyent][:sm_id].should eql '30'
      end

      it "should collect images" do
        @plugin[:joyent][:sm_image_id].should_not be_nil
        @plugin[:joyent][:sm_image_ver].should_not be_nil
      end

      it "should collect pkgsrc" do
        @plugin[:joyent][:sm_pkgsrc].should eql 'http://pkgsrc.joyent.com/packages/SmartOS/2013Q4/x86_64/All'
      end
    end
  end
end

