module main

import os
import toml

@[heap]
pub struct VigServiceInfo {
mut:
	name        string // it will set with key of map
	description string
}

fn (vsi VigServiceInfo) clone() VigServiceInfo {
	return VigServiceInfo{
		name: vsi.name.clone()
		description: vsi.description.clone()
	}
}

@[heap]
struct ReadyNotifyType {
mut:
	pipefd  int
	pipevar string
}

fn (rnt ReadyNotifyType) clone() ReadyNotifyType {
	return ReadyNotifyType{
		pipefd: rnt.pipefd
		pipevar: rnt.pipevar.clone()
	}
}

@[heap]
pub struct VigServiceService {
mut:
	type        string        // type of service! process, fork, oneshot, internal
	command     string        // I effort for parse this like shell
	timeout     int = 30      // seconds
	after       []string      // N/A yet
	before      []string      // N/A yet
	depends_on  []string      // wait for service to start successfully
	depends_ms  []string      // depends_on, but don't stop the service when marked services are stopped
	waits_for   []string      // runned after the process started.
	then_start  []string      // start services after exited successfully
	required_by []string      // it's needed because vig has built-in mount (it has changed to milestone)

	pid_file     string          // enter filepath, if file exists, record pid, then mark service runnin'
	start_string string          // find string to detect the service started successfully
	ready_notify ReadyNotifyType // S6 supervisioning suite - like activation

	restart_limit    int  // -1 to disable, 0 will not try to restart
	restart_smooth   bool // like dinit does not restart dependants
	runs_on_console  bool // start on console. with stdio.
	start_on_console bool // start on console. exclusively.

	set_var []string // merge variables
}

fn (vss VigServiceService) clone() VigServiceService {
	return VigServiceService{
		type: vss.type.clone()
		command: vss.command.clone()
		timeout: vss.timeout
		after: vss.after.clone()
		before: vss.before.clone()
		depends_on: vss.depends_on.clone()
		depends_ms: vss.depends_ms.clone()
		waits_for: vss.waits_for.clone()
		then_start: vss.then_start.clone()
		required_by: vss.required_by.clone()
		pid_file: vss.pid_file.clone()
		start_string: vss.start_string.clone()
		ready_notify: vss.ready_notify.clone()
		restart_limit: vss.restart_limit
		restart_smooth: vss.restart_smooth
		runs_on_console: vss.runs_on_console
		start_on_console: vss.start_on_console
		set_var: vss.set_var.clone()
	}
}

@[heap]
pub struct VigServiceMount {
mut:
	resource       string
	mount_to       string
	fs_type        string
	options        string
	require_rw     bool
	directory_mode string
}

fn (vsm VigServiceMount) clone() VigServiceMount {
	return VigServiceMount{
		resource: vsm.resource.clone()
		mount_to: vsm.mount_to.clone()
		fs_type: vsm.fs_type.clone()
		options: vsm.options.clone()
		require_rw: vsm.require_rw
		directory_mode: vsm.directory_mode.clone()
	}
}

pub enum ServiceState {
	stopped
	pending
	starting
	running
	failed
}

pub enum ServiceReason {
	user_specified
	dependency
}

@[heap]
struct VigServiceInternal {
mut:
	pid          int = -2
	state        int
	reason       int
	triggered_by []string
	//dependent    []string
}

fn (vsi VigServiceInternal) clone() VigServiceInternal {
	return VigServiceInternal{
		pid: vsi.pid
		state: vsi.state
		reason: vsi.reason
		triggered_by: vsi.triggered_by.clone()
	}
}

// service file
@[heap]
pub struct VigService {
pub mut:
	info     VigServiceInfo
	service  VigServiceService
	mount    VigServiceMount
	internal VigServiceInternal
}

fn (vs VigService) clone() VigService {
	return VigService{
		info: vs.info.clone()
		service: vs.service.clone()
		mount: vs.mount.clone()
		internal: vs.internal.clone()
	}

}

fn load_service_file(fpath string) !VigService {
	tom := toml.parse_file(fpath) or { return error('failed to load service file ${err}') }
	mut serv := VigService{}
	serv = tom.decode[VigService]() or { return error('failed to parse service') }
	serv.info.name = os.base(fpath)
	return serv
}

// mayB it improve performance
/*@[minify; packed]
pub struct VigServicePr {
	desc string

	type      [8]u8
	cmd       [64]u8
	args      string
	after     [][32]u8
	before    [][32]u8
	pidfile   string
	dependson [][32]u8
	dependshd [][32]u8
	waitsfor  [][32]u8
	// roc_soc   [1]u8
	r_console bool
	s_console bool

	resource ?string
	mountto  ?string
	fstype   ?[16]u8
	options  ?[64]u8
	reqrw    ?bool
	dirmode  ?[1]u8
}*/
