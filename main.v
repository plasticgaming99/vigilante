import os
import time
import syscall

fn signal_handler(sig os.Signal) {
	if sig == os.Signal.usr1 {
		syscall.shutdown() or { 
			print("failed to shut down")
		}
	} else
	if sig == os.Signal.int {
		syscall.reboot() or {
			println("failed to reboot")
		}
	}
}

fn signal_handler_noninit(sig os.Signal) {
	if sig == os.Signal.usr1 || sig == os.Signal.int {
		exit(0)
	}
}

fn handle_zombie() {
	for {
		pid := os.wait()
		if pid == -1 {
			time.sleep(1 * time.second)
		}
	}
}

fn walk_service_dir(fpath string, mut vserv map[string]VigService) {
	if os.is_dir(fpath) {
		return
	}
	if !(fpath.contains_any_substr([".service", ".mount", ".target"])) {
		return
	}

	unsafe {vserv[os.base(fpath)] = load_service_file(fpath) or {
		return
	}}
}

fn main() {
	//println(load_service_file("./test.service") or { err.str() })
	//exit(1)
	mut is_system_init := false
	mut is_system_mgr := false
	mut is_user_service_mgr := false
	mut service_dir := "/etc/vigilante.d/"
	mut vig_services := map[string]VigService{}

	if os.getpid() == 1 {
		is_system_init = true
	} else {
		if os.getuid() == 1 {
			is_system_mgr = true
		} else {
			is_user_service_mgr = true
		}
	}

	for i := 0; i < os.args.len; i++ {
		if os.args[i].starts_with("-") {
			if os.args[i] == "--system" || os.args[i] == "-s" {
				is_system_init = true
			} else
			if os.args[i] == "--service-dir" || os.args[i] == "-d" {
				if i+1 >  os.args.len {
					println("--service-dir/-d requires an argument")
				}
				if os.args[i+1] != "\0" {
					service_dir = os.args[i+1]
					i++
				}
			}
		}
	}

	if is_system_init {
		os.signal_opt(os.Signal.usr1, signal_handler) or {
			print("error during handling shutdown")
		}
		os.signal_opt(os.Signal.int, signal_handler) or {
			print("error during handling reboot")
		}
		go handle_zombie()
	} else {
		os.signal_opt(os.Signal.usr1, signal_handler_noninit) or {
			print("exited")
		}
		os.signal_opt(os.Signal.int, signal_handler_noninit) or {
			print("exited")
		}
	}

	mut v_s := &vig_services
	// load service files
	if is_system_init {
		os.walk(service_dir, fn [mut v_s] (s string) {
			walk_service_dir(s, mut v_s)
		})
	}
	println(vig_services.str())

	syscall.pause()
}
