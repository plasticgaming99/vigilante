module main

import os
import syscall
import quickev

const vig_service_nil = VigService{}

fn walk_service_dir(fpath string, mut vserv map[string]VigService) {
	if _unlikely_(os.is_dir(fpath)) {
		return
	}
	if !(fpath.contains_any_substr(['.service', '.mount', '.target'])) {
		return
	}

	unsafe {
		vserv[os.base(fpath)] = load_service_file(fpath) or { return }
	}
}

// check pid is to be watched.
fn (vr &VigRegistry) pid_to_service_name(pid int) ?string {
	for _, v_s in vr.vigsvcs {
		if v_s.internal.pid == pid {
			println('yes in ${v_s.info.name}')
			return v_s.info.name
		}
	}
	return none
}

enum VigProcessType {
	sys_init
	sys_serv
	user_serv
}

@[direct_array_access]
fn main() {
	// println(load_service_file("./test.service") or { err.str() })
	// exit(1)
	// global-variable-avoiding-zone start
	mut servicetype := VigProcessType.user_serv
	mut service_dir := '/etc/vigilante.d/boot.d'
	mut vig_registry := VigRegistry{}
	mut svc_dir_override := false

	// global-variable-avoiding-zone end

	if os.getpid() == 1 {
		servicetype = VigProcessType.sys_init
	}

	for i := 0; i < os.args.len; i++ {
		if os.args[i].starts_with('-') {
			if os.args[i] == '--sysinit' || os.args[i] == '-s' {
				servicetype = VigProcessType.sys_init
			} else if os.args[i] == '--sysserv' || os.args[i] == '-e' {
				servicetype = VigProcessType.sys_serv
			} else if os.args[i] == '--userserv' || os.args[i] == '-u' {
				servicetype = VigProcessType.user_serv
			} else if os.args[i] == '--service-dir' || os.args[i] == '-d' {
				if i + 1 > os.args.len {
					println('--service-dir/-d requires an argument')
				}
				if os.args.len > i + 1 {
					service_dir = os.args[i + 1]
					svc_dir_override = true
					i++
				}
			}
		} else {
			// maybe linux kernel's own. maybe
		}
	}

	if _likely_(servicetype == VigProcessType.sys_init) {
	} else {
		C.prctl(syscall.pr_set_child_subreaper)
	}

	if servicetype == VigProcessType.sys_serv && !svc_dir_override {
		service_dir = '/usr/vigilante.d/system.d'
	}

	mut v_r := &vig_registry

	// load service files
	if _likely_(servicetype == VigProcessType.sys_init) {
		os.walk(service_dir, fn [mut v_r] (s string) {
			walk_service_dir(s, mut v_r.vigsvcs)
		})
	}
	//println(vig_services.str())

	// find default target (entry point!!)
	// priority ordered by: default.target(best) -> default -> boot
	/*start_service(vig_services['default.target'] or {
		vig_services['default'] or { vig_services['boot'] }
	})*/

	// setup event loop
	mut qevloop := quickev.init_loop() or {
		println('Error initializing event loop!')
		exit(1)
	}
	qevloop.add_signal(os.Signal.usr1, fn () {
		println('hi im function')
	})
	qevloop.add_signal(os.Signal.int, fn () {
		println('reboot everything!!!')
		exit(0) // temp
	})
	qevloop.add_signal(os.Signal.chld, fn [mut vig_registry] () {
		sigchld_handler(mut vig_registry)
	})

	// let's make unix domain socket
	uds := syscall.create_unix_domain_socket("/tmp/vigctl.socket") or {
		println("error binding socket")
		exit(1)
	}

	// process vigctl
	qevloop.add_generalfd(uds, fn [mut vig_registry] (fd int) {
		mut buf := []u8{cap:1024}
		for {
			buf2 := [1024]u8{}
			i := C.read(fd, &buf2, buf2.len)
			if i < 0 {
				if C.errno == C.EAGAIN || C.errno == C.EINTR {
					continue
				}
				eprintln("reading error")
				exit(1)
			}
			buf << buf2[..i]
			if i < 1024 {
				break
			}
		}
		os.fd_write(fd, vigctl_do(buf.bytestr(), mut vig_registry))
	})

	//println('epoll fd:${qevloop.get_epollfd()}')
	//println('signal fd:${qevloop.get_signalfd()}')
	// st := os.input('one cmd')
	// os.execute(st)
	vig_registry.merge_required_by()
	println('welcome to linux')
	vig_registry.start_service_tree('default.target')

	qevloop.run()

	// this is test code.
}
