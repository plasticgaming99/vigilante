// micro signal handlers
module main

import syscall

// SIGCHLD: reap zombies, help supervising services
fn sigchld_handler(mut v_s_m map[string]VigService) {
	for {
		pid, stat := syscall.waitpid(-1, C.WNOHANG)
		println('zombie reaped? ${pid}')
		sname := v_s_m.pid_to_service_name(pid) or {"miss!"}
		if v_s_m[sname].internal.pid == pid {
			exstat := C.WEXITSTATUS(stat)
			println("status: ${exstat}")
			match v_s_m[sname].service.type {
				"process" {
					match exstat {
						0 {
							v_s_m[sname].internal.state = ServiceState.stopped
						}
						else {
							v_s_m[sname].internal.state = ServiceState.failed
						}
					}
				}
				"fork" {
					println("todo")
				}
				"oneshot" {
					match exstat {
						0 {
							v_s_m.service_started(sname)
						}
						else {
							v_s_m[sname].internal.state = ServiceState.failed
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
