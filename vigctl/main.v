module main

import syscall
import lib
import os
import x.json2

fn main() {
	println('placeholder!!')
	mut data := lib.VigDataType{
		proto_version: 1
		purpose: lib.vigctl_start
	}
	jsondata := json2.encode[lib.VigDataType](data)
	println(jsondata)

	println("connect to vigilante daemon")

	i := syscall.connect_unix_domain_socket("/tmp/vigctl.socket") or {
		println(err)
		exit(1)
	}

	//C.fcntl(i, C.F_SETFL, C.O_NONBLOCK)

	os.fd_write(i, jsondata)
	os.fd_close(i)
	println("something is written")
}