// provides service management methods

module main

import os
import syscall

fn (vr &VigRegistry) find_after(svcname string) []string {
	mut ret := []string{}
	for k, v in vr.vigsvcs {
		for s in v.service.after {
			if s.contains(svcname) {
				ret << k
				break
			}
		}
	}
	return ret
}

fn (vr &VigRegistry) find_before(svcname string) []string {
	mut ret := []string{}
	for k, v in vr.vigsvcs {
		for s in v.service.before {
			if s.contains(svcname) {
				ret << k
				break
			}
		}
	}
	return ret
}

fn (vr &VigRegistry) find_waits_for(svcname string) []string {
	mut ret := []string{}
	for k, v in vr.vigsvcs {
		for s in v.service.waits_for {
			if s.contains(svcname) {
				ret << k
				break
			}
		}
	}
	return ret
}

fn (vr &VigRegistry) find_required_by(svcname string) []string {
	mut ret := []string{}
	for k, v in vr.vigsvcs {
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
fn (mut vr VigRegistry) merge_required_by() {
	for k, v in vr.vigsvcs {
		mut req := vr.find_required_by(k)
		if req.len > 0 {
			if !v.service.depends_on.contains('vt_' + k) {
				for i := 0; i < req.len; i++ {
					req[i] = 'vt_' + req[i]
				}
				println('merged virtual target ${req}')
				vr.vigsvcs[k].service.depends_on << req
			}
		}
	}
}

fn (vr &VigRegistry) find_depends(svcname string) []string {
	mut ret := []string{}
	for k, v in vr.vigsvcs {
		for s in v.service.depends_on {
			if s.contains(svcname) {
				ret << k
				break
			}
		}
		for s in v.service.depends_ms {
			if s.contains(svcname) {
				ret << k
				break
			}
		}
	}
	return ret
}

fn (vr &VigRegistry) is_dependency_started(svc string) bool {
	mut dep := vr.vigsvcs[svc].service.depends_on.clone()
	dep << vr.vigsvcs[svc].service.depends_ms
	for i, _ in dep {
		if dep[i].starts_with("vt_") {
			dep[i] = dep[i].after("vt_")
		}
	}
	for _, s in dep {
		if vr.vigsvcs[s].internal.state != .running {
			return false
		}
	}
	return true
}

fn (mut vr VigRegistry) service_started(svc string) {
	vr.vigsvcs[svc].internal.state = .running
	for s in vr.find_depends(svc) {
		if vr.vigsvcs[s].internal.state == .pending {
			vr.start_service(s)
		}
	}
	for s in vr.find_waits_for(svc) {
		vr.start_service(s)
	}
}

fn (mut vr VigRegistry) service_stopped(svc string) {
	vr.vigsvcs[svc].internal.state = .stopped
	for s in vr.find_depends(svc) {
		if !vr.vigsvcs[s].service.restart_smooth {
		}
	}
}

// start process, handle internal too
fn (mut vr VigRegistry) start_process(svc string, reason ServiceReason) {
	if vr.vigsvcs[svc].service.command == '' {
		return
	}

	cmd_s := vr.vigsvcs[svc].service.command
	mut cmd := cmd_s.split(' ')
	if cmd.len > 1 {
		replacer := [
			'\$VIG_PID',
			os.getpid().str(),
		]
		cmd = cmd.map(it.replace_each(replacer))
	}

	pid := os.fork()
	if pid == 0 {
		mut args := []string{}
		if cmd.len > 1 {
			args = unsafe { cmd[1..] }
		}
		os.execvp(cmd[0], args) or {
			println('Failed to exec')
			exit(0)
		}
	}
	vr.vigsvcs[svc].internal.pid = pid
	return
}

fn (mut vr VigRegistry) start_service(svc string) {
	if !vr.is_dependency_started(svc) {
		vr.vigsvcs[svc].internal.state = .pending
		return
	}
	if vr.vigsvcs[svc].internal.state == .running {
		return
	}

	match vr.vigsvcs[svc].service.type {
		"process", "fork", "oneshot" {
			logsimple(svc)
			vr.start_process(svc, .dependency)
		}
		"internal" {
			logsimple(svc)
			vr.service_started(svc)
		}
		else {}
	}
}

// Start SERVICE, DFS, main implementation
@[direct_array_access]
fn (mut vr VigRegistry) start_service_tree(st string) {
	mut str := st
	mut graph := map[string][]string{}
	for k, _ in vr.vigsvcs {
		graph[k] = []string{}
	}

	for k, v in vr.vigsvcs {
		// depends on
		for dep in v.service.depends_on {
			mut depname := dep
			if depname.starts_with('vt_') {
				depname = depname.after('vt_')
			}
			if depname in vr.vigsvcs {
				graph[k] << dep
			}
		}
		// depends ms
		for dep in v.service.depends_ms {
			mut depname := dep
			if depname.starts_with('vt_') {
				depname = depname.after('vt_')
			}
			if depname in vr.vigsvcs {
				graph[k] << dep
			}
		}
	}

	mut processed := map[string]bool{}
	mut instack := map[string]bool{}
	mut stack := []string{}

	// println('graph!!! ${graph}')
	// println('maybe ${str}')

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
			if depname.starts_with('vt_') {
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
		if servname.starts_with('vt_') {
			servname = servname.after('vt_')
		}
		if servname in vr.vigsvcs {
			//println(servname)
			vr.start_service(servname)
		}
		processed[servname] = true
	}
}

// stops process
fn (mut vr VigRegistry) stop_process(svc string) {
	i := syscall.kill(vr.vigsvcs[svc].internal.pid, int(os.Signal.term))
	if i == 0 {
		vr.service_stopped(svc)
		return
	}
	return
}

// it stops services with some methods
fn (mut vr VigRegistry) stop_service(svname string) {
	match vr.vigsvcs[svname].service.type {
		"process" {
			vr.stop_process(svname)
		}
		"oneshot" {
			vr.service_stopped(svname)
		}
		"fork" {
			vr.stop_process(svname)
		}
		"internal" {
			vr.service_started(svname)
		}
		else {}
	}
}

// stops recursively
fn (vr &VigRegistry) stop_service_tree(svname string) {
}
