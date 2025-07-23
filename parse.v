module main

import os
import toml

@[heap]
pub struct VigServiceInfo {
mut:
	name        string // it will set with key of map
	description string
}

@[heap]
struct ReadyNotifyType {
pub mut:
	pipefd  int
	pipevar string
}

@[heap]
pub struct VigServiceService {
mut:
	type        string   // type of service! process, fork, oneshot, internal
	command     string  // I effort for parse like shell
	after       []string // N/A yet
	before      []string // N/A yet
	depends_on  []string // wait for service to start successfully
	depends_ms  []string // depends_on, but don't stop the service when marked services are stopped
	waits_for   []string // runned after the process started.
	then_start  []string // start services after exited successfully
	required_by []string // it's needed because vig has build-in mount

	pid_file     string  // enter filepath, if file exists, record pid, then mark service runnin'
	start_string string  // find string to detect the service started successfully
	ready_notify ReadyNotifyType // S6 supervisioning suite - like activation

	restart_limit    int  // -1 to disable, 0 will not try to restart
	restart_smooth   bool // like dinit does not restart dependants
	runs_on_console  bool // start on console. with stdio.
	start_on_console bool // start on console. exclusively.

	set_var []string // merge variables
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

enum ServiceState {
	stopped
	starting
	running
	failed
}

enum ServiceReason {
	user_specified
	dependency
}

@[heap]
struct VigServiceInternal {
mut:
	pid          int
	state        ServiceState
	reason       ServiceReason
	triggered_by []string
}

// service file
@[heap]
pub struct VigService {
mut:
	info     VigServiceInfo
	service  VigServiceService
	mount    VigServiceMount
	internal VigServiceInternal
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
