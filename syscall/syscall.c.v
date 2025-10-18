// bind C language syscall interfaces to V
module syscall

#include <unistd.h>
#include <linux/reboot.h>
#include <sys/reboot.h>
#include <signal.h>
#include <sys/syscall.h>

const sys_exec = C.__NR_execve
const sys_fork = C.__NR_fork
const sys_sigprocmask = C.__NR_rt_sigprocmask

pub fn wnohang() int {
	return C.WNOHANG
}

fn C.syscall(sysno int, ...voidptr) int

fn C.reboot(cmd int) int

pub fn sigprocmask(how int, set &u64, oldset &u64) int {
	return C.syscall(sys_sigprocmask, how, set, oldset, sizeof(set))
}

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

fn C.waidpid(pid int, status &int, options int) int

// return pid, status
pub fn waitpid(pid int, options int) (int, &int) {
	mut cstat := int(0)
	ret_pid := C.waitpid(pid, &cstat, options)
	return ret_pid, &cstat
}

pub fn kill(pid int, signal int) int {
	return C.kill(pid, signal)
}