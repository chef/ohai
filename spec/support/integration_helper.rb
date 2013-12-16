require 'tmpdir'

module IntegrationSupport 
  def when_plugins_directory(description, &block)
    context "When the plugins directory #{description}" do

      before(:each) do
        @plugins_directory = Dir.mktmpdir('ohai-plugins')
      end

      after(:each) do
        if @plugins_directory
          begin
            FileUtils.remove_entry_secure(@plugins_directory)
          ensure
            @plugins_directory = nil
          end
        end
      end

      def with_plugin(plugin_path, contents)
        filename = path_to(plugin_path)
        dir = File.dirname(filename)
        FileUtils.mkdir_p(dir) unless dir == '.'
        File.open(filename, 'w') do |file|
          file.write(contents)
        end
      end
      
      def path_to(plugin_path)
        File.expand_path(plugin_path, @plugins_directory)
      end

      def self.with_plugin(plugin_path, contents)
        before :each do
          with_plugin(plugin_path, contents)
        end
      end
    
      instance_eval(&block)
    end
  end

end
