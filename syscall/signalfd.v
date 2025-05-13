// bind C epoll to V
module syscall

#include <unistd.h>
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
	e := C.syscall(sys_epoll_create1, flags)
	if e < 0 {
		return error('failed')
	} else {
		return e
	}
}

@[typedef]
struct C.signalfd_siginfo {
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
	pad         [48]u8
}

struct SigSetFd {
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
		panic('Invalid signal ${sig}')
	}
	ss.val[0] |= u64(1) << (sig - 1)
}

/*fn setup_signalfd_fd(ss &SigSetFd) int {
	// 注意：signalfd の第2引数は void*、なので u64* でも安全
	return C.signalfd(-1, ss.val.data, 0)
}*/

pub fn signalfd(fd int, mask SigSetFd, flags int) int {
	return C.syscall(sys_signalfd, fd, &mask, (sizeof(mask.val)), flags)
}
