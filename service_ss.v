module main

import os

fn (v_s_m map[string]VigService) find_after(svcname string) []string {
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

fn (v_s_m map[string]VigService) find_before(svcname string) []string {
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

fn (v_s_m map[string]VigService) find_waits_for(svcname string) []string {
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

// Start PROCESS
// Enter path of command! It will supervised with event loop.
// why this fn exists? to make async-starting easier.
fn (v_s VigService) start_process() {
	cmd := v_s.service.command
	args := v_s.service.args.split(' ')
	pid := os.fork()
	if pid == 0 {
		os.execvp(cmd, args) or { panic('Failed to exec') }
	}
}

// Start SERVICE
fn (v_s_m map[string]VigService) start_service(str string) {
	svc := v_s_m[str] or {
		println('service "${str}" not found')
		return
	}

	if svc.service.depends_on.len != 0 {
		for i := 0; i < svc.service.depends_on.len; i++ {
			v_s_m.start_service(svc.service.depends_on[i])
		}
	}

	// TODO: rewrite,
	if svc.service.depends_ms.len != 0 {
		for i := 0; i < svc.service.depends_ms.len; i++ {
			v_s_m.start_service(svc.service.depends_ms[i])
		}
	}

	if svc.service.command != '' {
		svc.start_process()
	}

	println('reached target ${svc.info.name}')

	wf_s := v_s_m.find_waits_for(str)
	if 0 < wf_s.len {
		//println('starting waits_for services')
		for _, s in wf_s {
			v_s_m.start_service(s)
		}
	}
}
