# This defines the shared context with all the helper methods
shared_context 'Ohai Plugins', type: :ohai_plugin do

  # The plugin helper will take the symbol name provided as the subject to the
  # describe and create the Ohai plugin class and then instantiate that class
  # for use within the specifications.
  let(:plugin) do
    ohai_plugin_class = Ohai.plugin(subject) {}
    ohai_plugin_class.new(plugin_data, Ohai::Log)
  end

  # When an Ohai plugin is created there is a Hash of data that must be provided.
  # It is likely not important to provide data but allowing it to be overriden
  # here if necessary.
  let(:plugin_data) { Hash.new }

  # Loads the plugin source from the specified plugin_file helper
  let(:plugin_source) do
    File.read(calculated_plugin_file_path)
  end

  # Determine the plugin_path from the specified plugin_file
  let(:plugin_path) do 
    File.dirname(calculated_plugin_file_path)
  end
  # This helper defines the path to the plugin file. This must be specified
  # by the author of the specification. Without specifying it, overriding this
  # helper, an error is raised informing them that it must be specifed and
  # provides an example to get them started.
  let(:plugin_file) do
    raise %(
Please specify the path to the Ohai plugin relative within the plugins directory

Example:
    let(:plugin_file) { "windows/cpu.rb" }
 )
  end

  let(:calculated_plugin_file_path) do
    File.join PLUGIN_PATH, "#{plugin_file}#{File.extname(plugin_file) == '.rb' ? '' : '.rb'}"
  end

  let(:platform) { 'default' }

  # A Loader requires a controller. This controller may need to be overriden so
  # it is provided as a helper.
  let(:plugin_controller) { Ohai::System.new }
  # The plugin_loader will evaluate the source of the plugin with the controller
  let(:plugin_loader) { Ohai::Loader.new(plugin_controller) }

  #
  # Before each example we want to load the plugin from source. This asks the
  # plugin_loader to load the plugin from the specifed source and path and
  # evalute the contents as a version 7 ohai plugin.
  #
  before :each do
    capture_named_plugins!
    ps = plugin_source
    pp = plugin_path
    plugin_loader.instance_eval { load_v7_plugin_class(ps,pp) }
    if platform != 'default'
      allow(plugin).to receive(:collect_os).and_return(platform)
    end
  end

  after :each do
    restore_named_plugins!
  end


  # Ohai plugins are defined with a class, which is a constant, and
  # they are added to the this module. Capture any currently loaded
  # plugins before we add any new plugins.
  def capture_named_plugins!
    @named_plugins = Ohai::NamedPlugin.constants
  end

  # Examine the current list of plugins loaded and compare it to
  # what was found when we started. Remove all the plugins that
  # have been added since then.
  def restore_named_plugins!
    diff_plugins = Ohai::NamedPlugin.constants - @named_plugins
    diff_plugins.each do |plugin|
      Ohai::NamedPlugin.send(:remove_const,plugin)
    end
  end

  # This provides a new matcher when wanting to make assertions that the plugin
  # does provide the correct body of attributes. The Ohai plugin class returns
  # an array of attributes that it provides through `#provides_attrs` which
  # is evaluated to ensure that the expected value is within that list.

  # @see https://relishapp.com/rspec/rspec-expectations/v/2-4/docs/custom-matchers/define-matcher
  RSpec::Matchers.define :provide_attribute do |expected|
    match do |plugin|
      expect(plugin.class.provides_attrs).to include(expected)
    end

    failure_message do |actual|
      "Expected the plugin to provide '#{expected}'. Plugin's defined attributes: #{plugin.class.provides_attrs.map { |p| "'#{p}'" }.join(', ')}"
    end

    failure_message_when_negated do |actual|
      "Expected the plugin to NOT provide '#{expected}'. Plugin's defined attributes: #{plugin.class.provides_attrs.map { |p| "'#{p}'" }.join(', ')}"
    end
  end

  # Provide support for the plural provides_attribute so that the authors
  # of the specification can choose what they think makes the most sense
  alias_method :provides_attribute, :provide_attribute


  # This provides a new matcher when wanting to make assertions that the plugin
  # has the correct dependencies. The Ohai plugin returns an array of dependencies
  # that it provides through `#dependencies` which is evaluated to ensure that
  # the expected value is within that list.

  # @see https://relishapp.com/rspec/rspec-expectations/v/2-4/docs/custom-matchers/define-matcher
  RSpec::Matchers.define :depend_on_attribute do |expected|
    match do |plugin|
      expect(plugin.dependencies).to include(expected)
    end

    failure_message do |actual|
      "Expected the plugin to depend on '#{expected}'. Plugin's dependencies: #{plugin.dependencies.map { |d| "'#{d}'" }.join(', ')}"
    end

    failure_message_when_negated do |actual|
      "Expected the plugin to NOT depend on '#{expected}'. Plugin's dependencies: #{plugin.dependencies.map { |d| "'#{d}'" }.join(', ')}"
    end
  end

  # To make the process of verifying the attributes a little more streamlined
  # you can use this helper to request the attributes from the plugin itself.
  #
  # The attributes are not loaded into the plugin until the plugin is run.
  # Then the plugin will provide a top-level method that matches the first
  # element in the ohai 'provides' String.
  #
  # The remaining elements within the 'provides' are elements within the Mash
  # that must be traversed to get to the value desired. That is done here and
  # then returned.
  def plugin_attribute(attribute)
    begin
      plugin.run
    rescue Exception => e
      raise PluginFailedToRunError.new(plugin.name,calculated_plugin_file_path,e)
    end

    components = attribute.split('/')
    top_level_mash_name = components.first
    attributes = components[1..-1]

    top_level_mash = plugin.send(top_level_mash_name)

    if top_level_mash.nil? && !attributes.empty?
      raise PluginAttributeUndefinedError.new(attribute,{})
    end

    attributes.inject(top_level_mash) do |mash,child|
      begin
        mash[child]
      rescue Exception => e
        raise PluginAttributeUndefinedError.new(attribute, { top_level_mash_name => top_level_mash })
      end
    end
  end

  class PluginFailedToRunError < RuntimeError
    def initialize(plugin_name,plugin_path,exception)
      @plugin_name = plugin_name
      @plugin_path = plugin_path
      @exception = exception
      # Fix the backtrace path from the fixtures directory to the plugin file
      # Without this the stacktrace points to the plugins directory with a line number
      # which generates an error in RSpec. This essentially fixes that to replace the
      # path to the plugins directory to the specific plugin. Generating a sane error
      # message
      exception.backtrace.each_with_index do |trace, index|
        if trace =~ /lib\/ohai\/plugins:\d+/
          exception.backtrace[index] = trace.gsub('lib/ohai/plugins',plugin_path)
        end
      end
    end

    attr_reader :plugin_name, :plugin_path, :exception

    def message
      "Plugin #{plugin_name} #{plugin_path} failed:\n#{exception.message}"
    end
  end

  class PluginAttributeUndefinedError < RuntimeError
    def initialize(desired_attribute,plugin_attribute_data)
      @desired_attribute = desired_attribute
      @plugin_attribute_data = plugin_attribute_data

    end

    attr_reader :desired_attribute, :plugin_attribute_data

    def message
      "Plugin does not define attribute path '#{desired_attribute}'. Does the definition or test have a misspelling? Does the plugin properly initialize the entire attribute path?

Plugin Attribute Data:
#{plugin_attribute_data.to_yaml}\n---"
    end
  end

end