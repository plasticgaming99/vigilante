// micro signal handlers
module main

import syscall

// SIGCHLD: reap zombies, help supervising services
fn sigchld_handler(mut vr VigRegistry) {
	for {
		pid, stat := syscall.waitpid(-1, C.WNOHANG)
		println('zombie reaped? ${pid}')
		sname := vr.pid_to_service_name(pid) or {"miss!"}
		if vr.vigsvcs[sname].internal.pid == pid {
			exstat := C.WEXITSTATUS(stat)
			println("status: ${exstat}")
			match vr.vigsvcs[sname].service.type {
				"process" {
					match exstat {
						0 {
							vr.vigsvcs[sname].internal.state = ServiceState.stopped
						}
						else {
							vr.vigsvcs[sname].internal.state = ServiceState.failed
						}
					}
				}
				"fork" {
					println("todo")
				}
				"oneshot" {
					match exstat {
						0 {
							vr.service_started(sname)
						}
						else {
							vr.vigsvcs[sname].internal.state = ServiceState.failed
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
