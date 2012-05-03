class ::File
  def self.read_procfile(path)
    contents = ''
    File.open(path) do |f|
      loop do
        begin
          contents << f.read_nonblock(4096).strip
        rescue EOFError
          break
        rescue Errno::EWOULDBLOCK, Errno::EAGAIN
          contents = ''
          break # don't select file handle, just give up
        end
      end
    end
    contents.split("\n")
  end
end
