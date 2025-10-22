module main

import syscall
import lib as vigctllib
import os
import json

enum Control {
	start
	stop
	enable
	disable

	shutdown
}

struct VigCtlArgs {
mut:
	control     Control
	servicename string
}

fn (mut vca VigCtlArgs) parse(sa []string) {
	for i, s in sa {
		if i == 0 {
			match s {
				'start' { vca.control = .start }
				'stop' { vca.control = .stop }
				'enable' { vca.control = .enable }
				'disable' { vca.control = .disable }
				'shutdown' { vca.control = .shutdown }
				else {}
			}
			continue
		}
		if i > 0 {
			vca.servicename = s
			break
		}
	}
}

fn (ctrl Control) control_to_proto() string {
	mut s := ''
	match ctrl {
		.start { s = vigctllib.vigctl_start }
		.stop { s = vigctllib.vigctl_stop }
		.enable { s = vigctllib.vigctl_enable }
		.disable { s = vigctllib.vigctl_disable }
		.shutdown { s = vigctllib.vigctl_shutdown }
	}
	return s
}

fn main() {
	mut vca := VigCtlArgs{}
	vca.parse(unsafe { os.args[1..] })

	mut data := vigctllib.VigDataType{
		proto_version: 1
		purpose:       vca.control.control_to_proto()
		content:       vca.servicename
	}
	jsondata := json.encode(data)
	println(jsondata)

	println('connect to vigilante daemon')
	mut cnter := u64(0)
	for {
		fd := syscall.connect_unix_domain_socket('/tmp/vigctl.socket') or {
			println(err)
			exit(1)
		}

		// C.fcntl(i, C.F_SETFL, C.O_NONBLOCK)
		os.fd_write(fd, jsondata)
		mut buf := []u8{cap: 1024}
		for {
			buf2 := [1024]u8{}
			i := C.read(fd, &buf2, buf2.len)
			if i < 0 {
				if C.errno == C.EAGAIN || C.errno == C.EINTR {
					continue
				}
				eprintln('reading error')
				exit(1)
			}
			buf << buf2[..i]
			if i < 1024 {
				break
			}
		}
		bbstr := buf.bytestr()
		rt := json.decode(vigctllib.VigDataType, bbstr) or { vigctllib.VigDataType{} }
		println(rt.content)
		os.fd_close(fd)
		cnter++
		println(cnter)
		unsafe {
			bbstr.free()
			buf.free()
			rt.free()
		}
		// if cnter == 50000 {
		//	break
		//}
	}
}
