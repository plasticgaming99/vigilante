// Wraps small amount of C syscall to V
// foo fd epoll

module syscall

import os

#include <unistd.h>
#include <signal.h>
#include <sys/epoll.h>
#include <sys/signalfd.h>

const sys_epoll_create1 = C.__NR_epoll_create1
const sys_epoll_ctl = C.__NR_epoll_ctl
const sys_epoll_wait = C.__NR_epoll_wait
const sys_epoll_pwait = C.__NR_epoll_pwait
const sys_signalfd = C.__NR_signalfd
const sys_timerfd = C.__NR_timerfd
const sys_rt_sigprocmask = C.__NR_rt_sigprocmask

// todo: all

@[typedef]
pub struct C.epoll_data {
	ptr voidptr
	fd  int
	u32 u32
	u64 u64
}

pub struct C.epoll_event {
	events u32
	data   C.epoll_data
}

pub fn epoll_create1(flags int) !int {
	e := C.syscall(sys_epoll_create1, flags)
	if e < 0 {
		return error('failed')
	} else {
		return e
	}
}

pub fn epoll_ctl(epfd int, op int, fd int, mut event C.epoll_event) {
	event.data.fd = fd
	e := C.syscall(sys_epoll_ctl, epfd, op, fd, &event)
	if e == -1 {
		println(os.posix_get_error_msg(C.errno))
		println('omg')
		exit(1)
	}
}

pub fn epoll_wait(fd int, mut events []C.epoll_event, timeout int) !int {
	if events.len == 0 {
		error("buffer isn't usable, or not exists")
	}
	ret := C.syscall(sys_epoll_wait, fd, unsafe { &events[0] }, events.len, timeout)
	if ret < 0 {
		println(os.posix_get_error_msg(C.errno))
		return error('error calling syscall: epoll')
	}
	return ret
}

pub struct C.signalfd_siginfo {
	ssi_signo   u32
	ssi_errno   i32
	ssi_code    i32
	ssi_pid     u32
	ssi_uid     u32
	ssi_fd      i32
	ssi_tid     u32
	ssi_band    u32
	ssi_overrun u32
	ssi_trapno  u32
	ssi_status  i32
	ssi_int     i32
	ssi_ptr     u64
	ssi_utime   u64
	ssi_stime   u64
	ssi_addr    u64
	__pad       [28]u8
}

pub struct SigSetFd {
pub mut:
	val [1]u64
}

pub fn new_sigset_fd() SigSetFd {
	mut ssf := SigSetFd{}
	ssf.val = [1]u64{}
	return ssf
}

pub fn (mut ss SigSetFd) add(sig int) {
	if sig < 1 || sig > 64 {
		println('Invalid signal ${sig}')
		exit(0)
	}
	ss.val[0] |= u64(1) << (sig - 1)
}

/*fn setup_signalfd_fd(ss &SigSetFd) int {
	return C.signalfd(-1, ss.val.data, 0)
}*/

pub fn signalfd(fd int, mask SigSetFd, flags int) int {
	return C.syscall(sys_signalfd, fd, &mask, sizeof(mask.val), flags)
}

pub fn timerfd(fd int) {
}
