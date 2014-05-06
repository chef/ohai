provides "ulimit"


ulimits = Mash.new
ulimits['soft'] = Mash.new
ulimits['hard'] = Mash.new


[["sh -c 'ulimit -Sa'", ulimits['soft']],
 ["sh -c 'ulimit -Ha'", ulimits['hard']]
].each do |cmd,uhash|
  popen4(cmd) do |pid, stdin, stdout, stderr|
    stdin.close

    stdout.each do |line|
      case line
       when /^(.+)\s+(.+)$/
        uhash[$1.split('(')[0].strip] =  $2 == "unlimited" ? "unlimited" : $2.to_i
      end
    end
  end
end

ulimit ulimits




