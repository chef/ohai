require File.expand_path(File.dirname(__FILE__) + "/ohai_plugin_common.rb")

describe OhaiPluginCommon, "subsumes?" do
  before(:each) do
    @hash = { "languages" => { "python" => { "version" => "1.6.2", "type" => "interpreted" }}}
    @opc = OhaiPluginCommon.new
  end

  it "returns true if given an exact duplicate" do
    @opc.subsumes?( @hash, @hash ).should be_true
  end

  it "returns false if given an exact duplicate with extra info" do
    @opc.subsumes?( @hash, { "languages" => { "python" => { "version" => "1.6.2", "os" => "darwin", "type" => "interpreted" }}} ).should be_false
    @opc.subsumes?( @hash, { "languages" => { "python" => { "version" => "1.6.2", "os" => {}, "type" => "interpreted" }}} ).should be_false
    @opc.subsumes?( @hash, { "languages" => { "python" => { "version" => "1.6.2", "os" => { "name" => "darwin" }, "type" => "interpreted" }}} ).should be_false
  end

  it "returns true if all elements in the second hash are in the first hash" do
    @opc.subsumes?( @hash, { "languages" => { "python" => { "version" => "1.6.2" }}} ).should be_true
    @opc.subsumes?( @hash, { "languages" => { "python" => {}}} ).should be_true
    @opc.subsumes?( @hash, { "languages" => {}} ).should be_true
  end

  it "returns true if the second hash contains a key pointing to a nil where the first hash has nothing" do
    @opc.subsumes?( @hash, { "languages" => { "lua" => nil }} ).should be_true
    @opc.subsumes?( @hash, { "languages" => { "python" => { "version" => "1.6.2" }, "lua" => nil }} ).should be_true
  end
end
