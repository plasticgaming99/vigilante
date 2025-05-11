// bind C epoll to V
module syscall

#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <sys/epoll.h>
#include <sys/signalfd.h>

const sys_epoll_create1 = 291
const sys_epoll_ctl = 233
const sys_epoll_wait = 232
const sys_signalfd = 282
const sys_rt_sigprocmask = 14


// todo: all

pub fn epoll_create1(flags int) !int {
	e := C.syscall(sys_epoll_create1, flags, 0, 0, 0, 0, 0)
	if e < 0 {
		return error("failed")
	} else {
		return e
	}
}

pub struct SigSet {
    mut:
        data [16]u64 // 1024 signals
}

pub fn sigset_new(mask u64) SigSet {
    mut set := SigSet{}
    set.data[mask / 64] = u64(1) << (mask % 64)
    return set
}

pub fn signalfd(fd int, mask &SigSet, flags int) int {
    return C.syscall(sys_signalfd, fd, mask, voidptr(sizeof(SigSet)), flags, 0, 0)
}