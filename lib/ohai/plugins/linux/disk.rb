provides 'disk'

def disk_path(link)
  dir   = File.dirname(link)
  path  = File.readlink(link)

  File.expand_path(File.join(dir, path))
end

disks = Mash.new

by_path_root  = '/dev/disk/by-path'
by_label_root = '/dev/disk/by-label'
by_uuid_root  = '/dev/disk/by-uuid'

Dir.glob(File.join(by_path_root, '*')).each do |disk_name_link|
  disk_name = File.basename(disk_name_link)
  path      = disk_path(disk_name_link)

  disks[path] ||= Mash.new
  disks[path][:name] = disk_name
end

Dir.glob(File.join(by_label_root, '*')).each do |disk_label_link|
  disk_label = File.basename(disk_label_link)
  path       = disk_path(File.join(by_label_root, disk_label))

  disks[path] ||= Mash.new
  disks[path][:label] = disk_label
end

Dir.glob(File.join(by_uuid_root, '*')).each do |disk_uuid_link|
  disk_uuid = File.basename(disk_uuid_link)
  path      = disk_path(File.join(by_uuid_root, disk_uuid))

  disks[path] ||= Mash.new
  disks[path][:uuid] = disk_uuid
end

disk disks
