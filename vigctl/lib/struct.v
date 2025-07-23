module lib

pub const vigctl_enable = "enable"
pub const vigctl_disable = "disable"
pub const vigctl_start = "start"
pub const vigctl_stop = "stop"
pub const vigctl_status = "status"

pub struct VigDataType {
pub:
	proto_version int
	purpose string
}