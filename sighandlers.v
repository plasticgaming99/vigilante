// micro signal handlers
module main

import os
import syscall
import quickev

// SIGCHLD: reap zombies, help supervising services
fn sigchld_handler(mut vr VigRegistry) {
	for {
		pid, stat := syscall.waitpid(-1, C.WNOHANG)
		//println('zombie reaped? ${pid}')
		sname := vr.pid_to_service_name(pid) or {"miss!"}
		if vr.vigsvcs[sname].internal.pid == pid {
			exstat := C.WEXITSTATUS(*stat)
			//println("status: ${exstat}")
			match vr.vigsvcs[sname].service.type {
				"process" {
					match exstat {
						0 {
							vr.vigsvcs[sname].internal.state = int(ServiceState.stopped)
						}
						else {
							vr.vigsvcs[sname].internal.state = int(ServiceState.failed)
						}
					}
				}
				"fork" {
					println("todo")
				}
				"oneshot" {
					match exstat {
						0 {
							logsimple_started(sname)
							vr.service_started(sname)
						}
						else {
							vr.vigsvcs[sname].internal.state = int(ServiceState.failed)
						}
					}
				}
				"internal" {/* nothing */}
				else {
					println("Invailed service type detected.")
				}
			}
		}
		if pid <= 0 {
			break
		}
	}
}

@[heap]
struct VigctlHandler{
mut:
	v_r &VigRegistry
}

fn (mut vch VigctlHandler) vigctl_accept_handler(mut ql quickev.QevLoop, fd int) {
	ql.add_datafd(fd, vch.vigctl_cnfd_handler) or {}
}

fn (mut vch VigctlHandler) vigctl_cnfd_handler(mut ql quickev.QevLoop, fd int) {
	mut buf := []u8{}
	for {
		buf2 := [512]u8{}
		i := C.read(fd, &buf2, buf2.len)
		if i < 0 {
			if C.errno == C.EAGAIN || C.errno == C.EINTR {
				continue
			}
			eprintln("reading error")
		}
		buf << buf2[0..i]
		if i < buf2.len {
			break
		}
	}
	bstr := buf.bytestr()
	vig_result := vigctl_do(bstr, mut vch.v_r)
	os.fd_write(fd, vig_result)
	ql.del_datafd(fd)
}