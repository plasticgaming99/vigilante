# vigilante: an init system
my experiment that writing init with V<br>
much inspired by dinit

including:<br>
> vigilante, init<br>
> syscall,   wrap small amount of c language and linux syscall<br>
> quickev,   simple less-functional event loop<br>

> [!CAUTION]
> This init isn't battle tested, and stability is not guaranteed.
> Use with your own risk.

service file example:
```toml
[info]
description = "description"

[service]
type = "{process, fork, oneshot, internal}"
command = "command"
args = "args"
after = ["services"]
before = ["services"]
pid_file = "/path/to/pid/file"
depends_on = ["services"]
depends_ms = ["services"]
waits_for = ["services"]

[mount]
resource = "{device, file, or anything}"
mount_to = "/target/to/mount or none"
fs_type = "filesystem type"
options = "mount option"
require_rw = true #bool
directory_mode = "0755" #filemode
```
