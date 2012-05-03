class ::File
  # Use this to read files under /proc directory on linux in a non-blocking way. File.read.each and alike hangs
  # on linux kernels prior to 2.6.30 (which includes RHEL 5.7 current kernel as of 05/01/2012) due to a kernel bug, making shef unusable.
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
