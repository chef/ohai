#
#
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
tmp = ENV['TMPDIR'] || ENV['TMP'] || ENV['TEMP'] || '/tmp'

def create_plugin(path, contents)
  fi = File.open(path, "w+")
  fi.write(contents)
  fi.close
end

describe Ohai::Loader do
  describe "initialize" do
    it "should return an Ohai::Loader object" do
      loader = Ohai::Loader.new(Ohai::System.new)
      loader.should be_a_kind_of(Ohai::Loader)
    end
  end

  describe "#load_plugin" do
    before(:all) do
      begin
        Dir.mkdir("#{tmp}/plugins")
      rescue Errno::EEXIST
        # ignore
      end

      @plugin_path = Ohai::Config[:plugin_path]
      Ohai::Config[:plugin_path] = ["#{tmp}/plugins"]
    end

    before(:each) do
      @ohai = Ohai::System.new
      @loader = Ohai::Loader.new(@ohai)
      @loader.stub(:collect_provides).and_return(@ohai.attributes)
    end

    after(:each) do
      Dir[File.join("#{tmp}/plugins", "*.rb")].each do |file|
        File.delete(file)
      end
    end

    after(:all) do
      begin
        Dir.delete("#{tmp}/plugins")
      rescue
        # begin
      end

      Ohai::Config[:plugin_path] = @plugin_path
    end

    it "should warn if a plugin cannot be loaded" do
      Ohai::Log.should_receive(:warn).with(/Unable to open or read plugin/)
      @loader.load_plugin("fake.rb")
    end

    it "should detect and return a v6 plugin" do
      plugin_string = <<EOF
provides "thing"
thing Mash.new
EOF
      create_plugin("#{tmp}/plugins/v6.rb", plugin_string)
      Ohai::Log.should_receive(:warn).with(/[DEPRECATION]/)
      @loader.load_plugin("#{tmp}/plugins/v6.rb").version.should eql(:version6)
    end

    it "should detect and return a v7 plugin" do
      plugin_string = <<EOF
Ohai.plugin do
  provides "thing"
  collect_data do
    thing Mash.new
  end
end
EOF
      create_plugin("#{tmp}/plugins/v7.rb", plugin_string)
      @loader.load_plugin("#{tmp}/plugins/v7.rb").version.should eql(:version7)
    end

    it "should warn with NoMethodError when plugin uses non-dsl command" do
      plugin_string = <<EOF
Ohai.plugin do
  requires "thing"
end
EOF
      create_plugin("#{tmp}/plugins/broken.rb", plugin_string)
      Ohai::Log.should_receive(:warn).with(/[UNSUPPORTED OPERATION]/)
      @loader.load_plugin("#{tmp}/plugins.broken.rb")
    end
  end

  describe "#collect_provides" do
    before(:each) do
      @ohai = Ohai::System.new
      @loader = Ohai::Loader.new(@ohai)
    end

    it "should add a provided attribute to ohai attributes" do
      klass = Ohai.plugin { provides 'attribute' }
      plugin = klass.new(@ohai, "")
      @loader.collect_provides(plugin)
      @ohai.attributes.should have_key('attribute')
    end

    it "should add subattributes" do
      klass = Ohai.plugin { provides 'attribute/subattribute' }
      plugin = klass.new(@ohai, "")
      @loader.collect_provides(plugin)
      @ohai.attributes.should have_key('attribute')
      @ohai.attributes['attribute'].should have_key('subattribute')
    end

    it "should collect provides for a list" do
      klass = Ohai.plugin { provides 'one', 'two', 'three' }
      plugin = klass.new(@ohai, "")
      @loader.collect_provides(plugin)
      %w{ one two three }.each do |attr|
        @ohai.attributes.should have_key(attr)
      end
    end

    it "should add the providing plugin to attribute providers" do
      klass = Ohai.plugin { provides 'attribute' }
      plugin = klass.new(@ohai, "")
      @loader.collect_provides(plugin)
      @ohai.attributes['attribute']['providers'].should eql([plugin])
    end

    it "should add to the providers list for multiple providing plugins" do
      klasses = []
      2.times do
        klasses << Ohai.plugin { provides 'attribute' }
      end

      plugins = []
      klasses.each { |klass| plugins << klass.new(@ohai, "") }
      plugins.each { |plugin| @loader.collect_provides(plugin) }

      @ohai.attributes['attribute']['providers'].should eql(plugins)
    end
  end
end
