module Ohai
  class JsonParser
    # Choose the right json library based on whether we are in JRuby or not.
    if RUBY_PLATFORM == "java"
      require 'rubygems'
      require 'json'

      # Serialize this object as a hash
      def to_json(data)
        JSON[data]
      end

      # Pretty Print this object as JSON
      def json_pretty_print(data)
        JSON.pretty_generate(data)
      end
    else
      require 'yajl'

      # Serialize this object as a hash
      def to_json(data)
        Yajl::Encoder.new.encode(data)
      end

      # Pretty Print this object as JSON
      def json_pretty_print(data)
        Yajl::Encoder.new(:pretty => true).encode(data)
      end
    end
  end
end
