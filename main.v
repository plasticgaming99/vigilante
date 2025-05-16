module main

import os
import syscall
import quickev

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

// reap zomb
fn sigchld_handler() {
	syscall.waitpid(-1, C.WNOHANG)
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
		// os.signal_opt(os.Signal.usr1, signal_handler) or { print('error during handling shutdown') }
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

	// find default target (entry point!!)
	// priority ordered by: default.target(best) -> default -> boot
	/*start_service(vig_services['default.target'] or {
		vig_services['default'] or { vig_services['boot'] }
	})*/

	// setup event loop
	mut qevloop := quickev.init_loop() or { panic('Error initializing event loop!') }
	qevloop.add_signal(os.Signal.usr1, fn () {
		println('hi im function')
	})
	qevloop.add_signal(os.Signal.int, fn () {
		println('hi im function 2')
	})
	qevloop.add_signal(os.Signal.chld, fn () {
		println('hi im function 3, going to reap')
	})
	qevloop.finalize_signal() or { panic('Error during initializing event loop!') }
	println('epoll fd:${qevloop.epollfd}')
	println('signal fd:${qevloop.signalfd}')
	// st := os.input('one cmd')
	// os.execute(st)

	println('welcome to linux')
	vig_services.start_service('default.target')

	qevloop.run()

	// this is test code.
}
