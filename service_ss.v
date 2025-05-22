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

// merged with this.
fn (mut v_s_m map[string]VigService) merge_required_by() {
	for k, v in v_s_m {
		mut req := v_s_m.find_required_by(k)
		if req.len > 0 {
			if !v.service.depends_on.contains('vt_' + k) {
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
fn (mut v_s VigService) start_process(reason ServiceReason) {
	cmd := v_s.service.command
	mut args := []string{}
	if v_s.service.args != '' {
		replacer := [
			'\$VIG_PID',
			os.getpid().str(),
		]
		args = v_s.service.args.split(' ').map(it.replace_each(replacer))
	}
	pid := os.fork()
	if pid == 0 {
		os.execvp(cmd, args) or {
			println('Failed to exec')
			exit(0)
		}
	}
	v_s.internal.pid = pid
	return
}

// Start SERVICE, DFS, main implementation
fn (mut v_s_m map[string]VigService) start_service(st string) {
	mut str := st
	mut graph := map[string][]string{}
	for k, _ in v_s_m {
		graph[k] = []string{}
	}

	for k, v in v_s_m {
		// depends on
		for dep in v.service.depends_on {
			if dep in v_s_m {
				graph[k] << dep
			}
		}
		// depends ms
		for dep in v.service.depends_ms {
			if dep in v_s_m {
				graph[k] << dep
			}
		}
		// waits for
		for waits in v_s_m.find_waits_for(k) {
			if waits in v_s_m {
				graph[k] << waits
			}
		}
	}

	mut processed := map[string]bool{}
	mut instack := map[string]bool{}
	mut stack := []string{}

	println('graph!!! ${graph}')
	println('maybe ${str}')

	stack << str

	mut process := map[string]bool{}

	for stack.len > 0 {
		current := stack[stack.len - 1]
		if current in processed {
			stack.pop()
			continue
		}
		instack[current] = true
		mut processed_all := true

		for dep in graph[current] {
			mut depname := dep
			if depname.contains('vt_') {
				depname = depname.after('vt_')
			}
			if dep !in processed && dep !in instack {
				stack << dep
				processed_all = false
			}
		}

		if processed_all {
			stack.pop()
			instack[current] = false
			process[current] = false
		}
	}

	for serv in process.keys() {
		mut servname := serv
		if servname.contains('vt_') {
			servname = servname.after('vt_')
		}
		if servname in v_s_m {
			if v_s_m[serv].service.command != '' {
				v_s_m[serv].start_process(.dependency)
			}
		}
		logsimple(servname)
		processed[servname] = true
	}
}

// Start SERVICE, previous implement!! should removed with gc sections!!
fn (mut v_s_m map[string]VigService) start_service_recursive(str string) {
	mut s := str
	if str.contains('vt_') {
		s = str.after('vt_')
	}
	if v_s_m[s].service.depends_on.len != 0 {
		for i := 0; i < v_s_m[s].service.depends_on.len; i++ {
			v_s_m.start_service_recursive(v_s_m[s].service.depends_on[i])
		}
	}

	// TODO: rewrite,
	if v_s_m[s].service.depends_ms.len != 0 {
		for i := 0; i < v_s_m[s].service.depends_ms.len; i++ {
			v_s_m.start_service_recursive(v_s_m[s].service.depends_ms[i])
		}
	}

	if v_s_m[s].service.command != '' {
		v_s_m[s].start_process(ServiceReason.dependency)
	}

	match v_s_m[s].info.name.after('.') {
		'target' {
			println('reached target ${v_s_m[s].info.name}')
		}
		'service' {
			println('starting service ${v_s_m[s].info.name}')
		}
		'mount' {
			println('mounted ${v_s_m[s].info.name}')
		}
		else {
			println('runned unknown ${v_s_m[s].info.name}')
		}
	}

	wf_s := v_s_m.find_waits_for(s)
	if 0 < wf_s.len {
		// println('starting waits_for services')
		for _, st in wf_s {
			v_s_m.start_service_recursive(st)
		}
	}
}
