#include <unistd.h>
#include <linux/reboot.h>
#include <sys/reboot.h>
#include <signal.h>

fn C.reboot(cmd int) int

pub fn shutdown() ! {
	code := C.reboot(C.LINUX_REBOOT_CMD_POWER_OFF)
	if code != 0 {
		return error("failed to shutdown")
	}
}

pub fn halt() ! {
	code := C.reboot(C.LINUX_REBOOT_CMD_HALT)
	if code != 0 {
		return error("failed to halt")
	}
}

pub fn reboot() ! {
	code := C.reboot(C.LINUX_REBOOT_CMD_RESTART)
	if code != 0 {
		return error("failed to restart")
	}
}

pub fn C.mount(source string, target string, fstype string, mountflags u32, data ?) int

pub fn C.pause()