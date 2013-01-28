provides "openvz"
# Sample output
#Version: 2.5
#       uid  resource                     held              maxheld              barrier                limit              failcnt
#   852638:  kmemsize                 16595303             21577728             67108864             75497472                    0
#            lockedpages                     0                    0                   64                   64                    0
#            privvmpages                239894               258143               393216               442368                  161
#            shmpages                      653                 1005               262144               262144                    0
#            dummy                           0                    0                    0                    0                    0
#            numproc                       106                  168                 1024                 1024                    0
#            physpages                   96664               216508               262144  9223372036854775807                    0
#            vmguarpages                     0                    0               393216  9223372036854775807                    0
#            oomguarpages                80857                82836               262144  9223372036854775807                    0
#            numtcpsock                      5                    7                 5120                 5120                    0
#            numflock                        1                    7                 1024                 1024                    0
#            numpty                          1                    3                   64                   64                    0
#            numsiginfo                      0                   69                  512                  512                    0
#            tcpsndbuf                  146192               338032             10485760             15728640                    0
#            tcprcvbuf                   81920              7541904             10485760             15728640                    0
#            othersockbuf                25432                65760              4194304              8388608                    0
#            dgramrcvbuf                     0                 2312              1048576              1048576                    0
#            numothersock                   95                  105                 1024                 1024                    0
#            dcachesize                6900492              9437184              8388608              9437184                    0
#            numfile                       348                  520                10240                10240                    0
#            dummy                           0                    0                    0                    0                    0
#            dummy                           0                    0                    0                    0                    0
#            dummy                           0                    0                    0                    0                    0
#            numiptent                      20                   20                 2048                 2048                    0


openvz Mash.new

if File.exists?("/proc/user_beancounters")
  Ohai::Log.debug("OpenVZ: user_beancounters detected")

  File.open("/proc/user_beancounters").each do |line|
    line =~ /\s(\w+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/
    resource, held, maxheld, barrier, limit, failcnt = $1, $2, $3, $4, $5, $6

    next if ["dummy",nil].include? resource # skip header line and dummy resources

    openvz[resource] = Mash.new
    openvz[resource]["held"]    = held.to_i
    openvz[resource]["maxheld"] = maxheld.to_i
    openvz[resource]["barrier"] = barrier.to_i
    openvz[resource]["limit"]   = limit.to_i
    openvz[resource]["failcnt"] = failcnt.to_i
  end

  openvz["memory"] = Mash.new

  openvz["memory"]["total"] = openvz["oomguarpages"]["barrier"] * 4 #kb // sizeof(page)
end
