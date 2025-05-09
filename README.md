# vigilante: an init system
my experiment that writing init with V

service file example:
```toml
[info]
description = "description"

[service]
type = "{process, fork, script, internal}"
command = "command"
args = "args"
pid-file = "/path/to/pid/file"
depends-on = "(services)"
depends-hard = "(services)"
waits-for = "(services)"

[mount]
resource = "{device, file, or anything}"
mount-to = "/target/to/mount or none"
fs-type = "filesystem type"
options = "mount option"
require-rw = true #bool
directory-mode = 0755 #filemode
```
