module main

import os
import toml

pub struct VigServiceInfo {
mut:
	name        string // it will set with key of map
	description string
}

pub struct VigServiceService {
mut:
	type             string   // type of service! process, fork, script, internal
	command          string   // name of command to start! only one.
	args             string   // arguments. may be separated
	after            []string //
	before           []string //
	pid_file         string   //
	depends_on       []string //
	depends_ms       []string //
	waits_for        []string // runned after the process started.
	runs_on_console  bool     // start on console. with stdio.
	start_on_console bool     // start on console. exclusively.
}

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

struct VigServiceInternal {
mut:
	pid          int
	state        ServiceState
	reason       ServiceReason
	triggered_by string
}

// service file
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
	unsafe {
		free(tom)
	}
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
