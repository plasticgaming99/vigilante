// provides service management methods

module main

import os

fn (v_s_m &map[string]VigService) find_after(svcname string) []string {
	mut ret := []string{}
	for k, v in v_s_m {
		for s in v.service.after {
			if s.contains(svcname) {
				ret << k
				break
			}
		}
	}
	return ret
}

fn (v_s_m &map[string]VigService) find_before(svcname string) []string {
	mut ret := []string{}
	for k, v in v_s_m {
		for s in v.service.before {
			if s.contains(svcname) {
				ret << k
				break
			}
		}
	}
	return ret
}

fn (v_s_m &map[string]VigService) find_waits_for(svcname string) []string {
	mut ret := []string{}
	for k, v in v_s_m {
		for s in v.service.waits_for {
			if s.contains(svcname) {
				ret << k
				break
			}
		}
	}
	return ret
}

fn (v_s_m &map[string]VigService) find_required_by(svcname string) []string {
	mut ret := []string{}
	for k, v in v_s_m {
		for s in v.service.required_by {
			if s.contains(svcname) {
				ret << k
				break
			}
		}
	}
	return ret
}

fn (mut v_s_m map[string]VigService) merge_required_by() {
	for k, v in v_s_m {
		mut req := v_s_m.find_required_by(k)
		if req.len > 0 {
			if !v.service.depends_on.contains(k) {
				for i := 0; i < req.len; i++ {
					req[i] = 'vt_' + req[i]
				}
				println('merged ${req}')
				v_s_m[k].service.depends_on << req
			}
		}
	}
}

// Start PROCESS
// Enter path of command! It will supervised with event loop.
// why this fn exists? to make async-starting easier.
fn (mut v_s VigService) start_process() int {
	cmd := v_s.service.command
	args := v_s.service.args.split(' ')
	val := os.fork()
	if val == 0 {
		os.execvp(cmd, args) or {
			println('Failed to exec')
			exit(0)
		}
	}
	return val
}

// Start SERVICE
fn (mut v_s_m map[string]VigService) start_service(str string) {
	mut s := str
	if str.contains('vt_') {
		s = str.after('vt_')
	}
	if v_s_m[s].service.depends_on.len != 0 {
		for i := 0; i < v_s_m[s].service.depends_on.len; i++ {
			v_s_m.start_service(v_s_m[s].service.depends_on[i])
		}
	}

	// TODO: rewrite,
	if v_s_m[s].service.depends_ms.len != 0 {
		for i := 0; i < v_s_m[s].service.depends_ms.len; i++ {
			v_s_m.start_service(v_s_m[s].service.depends_ms[i])
		}
	}

	if v_s_m[s].service.command != '' {
		pid := v_s_m[s].start_process()
		v_s_m[s].internal.pid = pid
	}

	println('reached target ${v_s_m[s].info.name}')

	wf_s := v_s_m.find_waits_for(s)
	if 0 < wf_s.len {
		// println('starting waits_for services')
		for _, st in wf_s {
			v_s_m.start_service(st)
		}
	}
}
