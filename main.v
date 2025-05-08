import os
import time

fn signal_handler(sig os.Signal) {
	if sig == os.Signal.usr1 {
		shutdown() or { 
			print("failed to shut down")
		}
	} else
	if sig == os.Signal.int {
		reboot() or {
			println("failed to reboot")
		}
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

fn main() {
	mut is_system_init := false
	mut service_dir := "/"

	if os.getpid() == 1 {
		is_system_init = true
	}

	for i := 0; i < os.args.len; i++ {
		if os.args[i].starts_with("-") {
			if os.args[i] == "--system" || os.args[i] == "-s" {
				is_system_init = true
			} else
			if os.args[i] == "--service-dir" || os.args[i] == "-d" {
				if i < os.args.len {
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
	}

	C.pause()
}
