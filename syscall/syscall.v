// bind C language syscall interfaces to V
module syscall

#include <unistd.h>
#include <linux/reboot.h>
#include <sys/reboot.h>
#include <signal.h>
#include <sys/syscall.h>

fn C.syscall(sysno int, arg1 voidptr, arg2 voidptr, arg3 voidptr, arg4 voidptr, arg5 voidptr, arg6 voidptr) int

fn C.reboot(cmd int) int

pub fn shutdown() ! {
	code := C.reboot(C.LINUX_REBOOT_CMD_POWER_OFF)
	if code != 0 {
		return error('failed to shutdown')
	}
}

pub fn halt() ! {
	code := C.reboot(C.LINUX_REBOOT_CMD_HALT)
	if code != 0 {
		return error('failed to halt')
	}
}

pub fn reboot() ! {
	code := C.reboot(C.LINUX_REBOOT_CMD_RESTART)
	if code != 0 {
		return error('failed to restart')
	}
}

fn C.mount(source string, target string, fstype string, mountflags u32, data ?) int
pub fn mount(source string, target string, fstype string, mountflafs u32, data ?) ! {
	code := C.mount(source, target, fstype, mountflafs, data)
	if code != 0 {
		return error('failed to mount')
	}
}

fn C.pause()
pub fn pause() {
	C.pause()
}
