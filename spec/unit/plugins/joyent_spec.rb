require 'spec_helper'


describe Ohai::System, "plugin joyent" do
  before(:each) do
    @plugin = get_plugin('joyent')
  end

  describe "without joyent" do
    before(:each) do
      allow(@plugin).to receive(:is_smartos?).and_return(false)
    end

    it "should NOT create joyent" do
      @plugin.run
      expect(@plugin[:joyent]).to be_nil
    end
  end

  describe "with joyent" do
    before(:each) do
      allow(@plugin).to receive(:is_smartos?).and_return(true)
      @plugin[:virtualization] = Mash.new
      @plugin[:virtualization][:guest_uuid] = "global"
    end

    it "should create joyent" do
      @plugin.run
      expect(@plugin[:joyent]).not_to be_nil
    end

    describe "under global zone" do
      before(:each) do
        @plugin.run
      end

      it "should ditect global zone" do
        expect(@plugin[:joyent][:sm_uuid]).to eql 'global'
      end

      it "should NOT create sm_id" do
        expect(@plugin[:joyent][:sm_id]).to be_nil
      end
    end

    describe "under smartmachine" do
      before(:each) do
        @plugin[:virtualization][:guest_uuid] = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx'
        @plugin[:virtualization][:guest_id] = '30'
        allow(@plugin).to receive(:collect_product_file).and_return(["Name: Joyent Instance", "Image: base64 13.4.2", "Documentation: http://wiki.joyent.com/jpc2/SmartMachine+Base"])
        allow(@plugin).to receive(:collect_pkgsrc).and_return('http://pkgsrc.joyent.com/packages/SmartOS/2013Q4/x86_64/All')
        @plugin.run
      end

      it "should retrive zone uuid" do
        expect(@plugin[:joyent][:sm_uuid]).to eql 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx'
      end

      it "should collect sm_id" do
        expect(@plugin[:joyent][:sm_id]).to eql '30'
      end

      it "should collect images" do
        expect(@plugin[:joyent][:sm_image_id]).not_to be_nil
        expect(@plugin[:joyent][:sm_image_ver]).not_to be_nil
      end

      it "should collect pkgsrc" do
        expect(@plugin[:joyent][:sm_pkgsrc]).to eql 'http://pkgsrc.joyent.com/packages/SmartOS/2013Q4/x86_64/All'
      end
    end
  end
end

