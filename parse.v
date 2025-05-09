import toml

pub struct VigServiceInfo {
	description string
}

pub struct VigServiceService {
	type string
	command string
	args string
	pid_file string
	depends_on []string
	depends_hard []string
	waits_for []string
}

pub struct VigServiceMount {
	resource string
	mount_to string
	fs_type string
	options string
	require_rw bool
	directory_mode int
}

// service file
pub struct VigService {
	info VigServiceInfo
	service VigServiceService
	mount VigServiceMount
}

fn load_service_file(fpath string) !VigService {
	tom := toml.parse_file(fpath) or {
		return error("failed to load service file ${err}")
	}
	mut serv := VigService{}
	serv = tom.decode[VigService]() or {
		return error("failed to parse service")
	}
	return serv
}