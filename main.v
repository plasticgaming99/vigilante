module main

import os
import syscall

fn signal_handler(sig os.Signal) {
	if sig == os.Signal.usr1 {
		syscall.shutdown() or { print('failed to shut down') }
	} else if sig == os.Signal.int {
		syscall.reboot() or { println('failed to reboot') }
	}
}

fn signal_handler_noninit(sig os.Signal) {
	if sig == os.Signal.usr1 || sig == os.Signal.int {
		exit(0)
	}
}

fn handlezombiechld(sig os.Signal) {
	if sig == os.Signal.chld {
		handle_zombie()
	}
}

fn handle_zombie() {
	pid, status := syscall.waitpid(-1, syscall.wnohang())
	println('process exited pid:${pid} exitcode:${status}')
}

fn walk_service_dir(fpath string, mut vserv map[string]VigService) {
	if os.is_dir(fpath) {
		return
	}
	if !(fpath.contains_any_substr(['.service', '.mount', '.target'])) {
		return
	}

	unsafe {
		vserv[os.base(fpath)] = load_service_file(fpath) or { return }
	}
}

fn callbacktest(fd int, events int, loop voidptr) {
	println('callback')
	println(fd)
	println(events)
	println(loop.str())
	// println(pico)
}

@[direct_array_access]
fn main() {
	// println(load_service_file("./test.service") or { err.str() })
	// exit(1)
	mut is_system_init := false
	// mut is_user_service_mgr := false
	mut service_dir := '/etc/vigilante.d/boot.d'
	mut vig_services := map[string]VigService{}

	if os.getpid() == 1 {
		is_system_init = true
	}

	for i := 0; i < os.args.len; i++ {
		if os.args[i].starts_with('-') {
			if os.args[i] == '--system' || os.args[i] == '-s' {
				is_system_init = true
			} else if os.args[i] == '--service-dir' || os.args[i] == '-d' {
				if i + 1 > os.args.len {
					println('--service-dir/-d requires an argument')
				}
				if os.args[i + 1] != '\0' {
					service_dir = os.args[i + 1]
					i++
				}
			}
		}
	}

	if _likely_(is_system_init) {
		os.signal_opt(os.Signal.usr1, signal_handler) or { print('error during handling shutdown') }
		// os.signal_opt(os.Signal.int, signal_handler) or { print('error during handling reboot') }
		// go handle_zombie()
	} else {
		os.signal_opt(os.Signal.usr1, signal_handler_noninit) or { print('exited') }
		os.signal_opt(os.Signal.int, signal_handler_noninit) or { print('exited') }
	}

	mut v_s := &vig_services
	// load service files
	if _likely_(is_system_init) {
		os.walk(service_dir, fn [mut v_s] (s string) {
			walk_service_dir(s, mut v_s)
		})
	}
	println(vig_services.str())

	println((vig_services.len))

	// find default target (entry point!!)
	// priority ordered by: default.target(best) -> default -> boot
	println(vig_services['default.target'] or {
		vig_services['default'] or { vig_services['boot'] }
	})

	// os.signal_opt(os.Signal.chld, handlezombiechld) or { panic('ohhh zombie') }

	epoll := syscall.epoll_create1(0) or {
		println(err)
		exit(1)
	}

	println('epoll ${epoll}')

	mut sigsetsub := syscall.new_sigset_fd()
	sigsetsub.add(int(os.Signal.usr1))
	sigsetsub.add(int(os.Signal.int))
	sigsetsub.add(int(os.Signal.chld))
	os.signal_ignore(.usr1)
	os.signal_ignore(.int)
	os.signal_ignore(.chld)

	signalfd := syscall.signalfd(-1, sigsetsub, C.SFD_NONBLOCK | C.SFD_CLOEXEC)
	if signalfd == 1 {
		println(os.posix_get_error_msg(C.errno))
		exit(0)
	}

	println('signalfd ${signalfd}')

	// pico_conf := picoev.Config{}
	// mut pico_loop := picoev.new(pico_conf) or { panic('failed to create loop') }
	// pico_loop.add(signalfd, picoev.max_queue, -1, callbacktest)

	// this is test code.
	st := os.input('onecmd')
	os.execute(st)
	strr, btt := os.fd_read(signalfd, 1000)
	println('${strr.str} ${btt.str()}')

	// syscall.pause()
}
