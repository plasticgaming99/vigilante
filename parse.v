import toml

@[minify; packed]
pub struct VigServiceInfo {
	description string
}

@[minify; packed]
pub struct VigServiceService {
	type             string
	command          string
	args             string
	after            string
	before           string
	pid_file         string
	depends_on       []string
	depends_hard     []string
	waits_for        []string
	runs_on_console  bool
	start_on_console bool
}

@[minify; packed]
pub struct VigServiceMount {
	resource       string
	mount_to       string
	fs_type        string
	options        string
	require_rw     bool
	directory_mode string
}

// service file
@[minify; packed]
pub struct VigService {
	info    VigServiceInfo
	service VigServiceService
	mount   VigServiceMount
}

fn load_service_file(fpath string) !VigService {
	tom := toml.parse_file(fpath) or { return error('failed to load service file ${err}') }
	mut serv := VigService{}
	serv = tom.decode[VigService]() or { return error('failed to parse service') }
	unsafe {
		free(tom)
	}
	return serv
}

@[minify; packed]
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
}
