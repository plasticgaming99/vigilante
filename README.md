# vigilante: an init system
my experiment that writing init with V

including
  vigilante, init
  syscall,   wrap c language and linux syscall
  quickev,   simple less-functional event loop

service file example:
```toml
[info]
description = "description"

[service]
type = "{process, fork, script, internal}"
command = "command"
args = "args"
after = ["services"]
before = ["services"]
pid_file = "/path/to/pid/file"
depends_on = ["services"]
depends_hard = ["services"]
waits_for = ["services"]

[mount]
resource = "{device, file, or anything}"
mount_to = "/target/to/mount or none"
fs_type = "filesystem type"
options = "mount option"
require_rw = true #bool
directory-mode = "0755" #filemode
```
