module Ohai
  module Mixin
    require 'tempfile'
    require 'ohai/mixin/command_splitter'

    # This class understands how to execute a command using the Java's ProcessBuilder. Since Java does not support
    # fork, we cannot use the usual open4 library. We need to use this instead. Refer to the documentation of
    # java.lang.ProcessBuilder for more information on how this works.
    class JrubyCommand

      include Ohai::Mixin::CommandSplitter

      def initialize command
        @command = command
      end

      def execute
        pumper_type, out, err  = start(@command)
        @out_file = Tempfile.new("out_file")
        @err_file = Tempfile.new("err_file")
        @out_pumper = pumper_type.new(out, @out_file)
        @err_pumper = pumper_type.new(err, @err_file)
        status = @process.waitFor
        die
        @out_file.rewind
        @err_file.rewind
        out = @out_file.read
        err = @err_file.read
        return Class.new() do

          def initialize(status)
            @status = status
          end

          def exitstatus
            @status
          end
        end.new(status), out, err
      end

      private

      def start(command)
        require 'java'
        pb = java.lang.ProcessBuilder.new(split_command(command))
        ENV.each do |key, val|
          pb.environment[key] = val
        end
        @process = pb.start()
        return Class.new(StreamPumper) do
          def data_available?
            @stream.ready
          end

          def read
            @stream.read_line
          end

          def stop_pumping!
            super
            @stream.close
          end
        end, buf_reader(@process.input_stream), buf_reader(@process.error_stream)
      end

      def buf_reader stream
        java.io.BufferedReader.new(java.io.InputStreamReader.new(stream))
      end

      def die
        @out_pumper.stop_pumping!
        @err_pumper.stop_pumping!
      end

      # We need to consume the out and error streams of the started process. If not, the process hangs for them to be consumes once the buffer
      # fills up. So, we read them out and store them in a file so that it can consumed later
      class StreamPumper
        def initialize stream, file
          @stream, @file = stream,file
          @thd = Thread.new { pump }
        end

        def pump
          loop do
            data_available? && flush_stream
            Thread.current[:stop_pumping] && break
            sleep 0.001
          end
        end

        def flush_stream
          @file.write(read)
          @file.flush
        end

        def stop_pumping!
          @thd[:stop_pumping] = true
          @thd.join
        end
      end
    end
  end
end
