// quickev is a single threaded event loop librrary
// not recommended for using in network applications
// only epoll/linux-fds is available currently
@[manualfree]
module quickev

import os
import syscall

#include <unistd.h>
#include <signal.h>
#include <sys/epoll.h>
#include <sys/signalfd.h>

// max event
const maxevent = 512

struct SignalWatcher {
	callback fn () @[required]
	signal   os.Signal
}

// loop structure.
pub struct QevLoop {
mut:
	sigwatch      []SignalWatcher
	signalfd_mask syscall.SigSetFd
	sfdepollev    C.epoll_event
	signalfd      int = -1
	timerfd       int = -1
	accepterfd    map[int]fn (mut ql QevLoop, fd int)
	datafd        map[int]fn (mut ql QevLoop, fd int)
	epollfd       int = -1
	unregist_fd   []int
}

pub fn init_loop() !QevLoop {
	mut ql := QevLoop{
		epollfd: syscall.epoll_create1(C.O_CLOEXEC) or { return err }
	}
	return ql
}

pub fn (ql &QevLoop) get_epollfd() int {
	return ql.epollfd
}

// add_signal adds signal handling to event loop
// Must be finalized with finalize_signal.
// For approach to efficiency.
pub fn (mut ql QevLoop) add_signal(sig os.Signal, cb fn ()) {
	ql.sigwatch << SignalWatcher{
		callback: cb
		signal:   sig
	}
}

pub fn (ql &QevLoop) get_signalfd() int {
	return ql.signalfd
}

// this method will automatically executed
fn (mut ql QevLoop) finalize_signal() ! {
	mut ssfd := syscall.new_sigset_fd()
	for swt in ql.sigwatch {
		ssfd.add(int(swt.signal))
	}
	syscall.sigprocmask(C.SIG_BLOCK, &ssfd.val[0], unsafe { nil })
	unsafe {ssfd.free()}
	sfd := syscall.signalfd(-1, ssfd, C.SFD_NONBLOCK | C.O_CLOEXEC)
	println(os.posix_get_error_msg(C.errno))
	if sfd == -1 {
		error('failed to create signalfd')
	}
	ql.signalfd = sfd
	ql.signalfd_mask = ssfd
	ql.sfdepollev.events = u32(C.EPOLLIN|C.EPOLLET)
	mut e_ev := &ql.sfdepollev
	syscall.epoll_ctl(ql.epollfd, C.EPOLL_CTL_ADD, ql.signalfd, mut e_ev)
}

// set accepterfd
// you can gain connection fds
pub fn (mut ql QevLoop) add_accepterfd(fd int, cb fn (mut ql QevLoop, fd int)) {
	ql.accepterfd[fd] = cb

	mut ev := C.epoll_event{}
	ev.events = u32(C.EPOLLIN|C.EPOLLET)
	ev.data.fd = fd
	C.fcntl(fd, C.F_SETFL, C.O_NONBLOCK)
	syscall.epoll_ctl(ql.epollfd, C.EPOLL_CTL_ADD, fd, mut ev)
}

@[inline]
pub fn (mut ql QevLoop) del_accepterfd(datafd int) {
	ql.unregist_fd << datafd
}

fn (mut ql QevLoop) unregister_accepterfd(accfd int) {
	mut ev := C.epoll_event{}
	syscall.epoll_ctl(ql.epollfd, C.EPOLL_CTL_DEL, accfd, mut ev)
	ql.accepterfd.delete(accfd)
	os.fd_close(accfd)
}

pub fn (mut ql QevLoop) add_datafd(fd int, cb fn (mut ql QevLoop, fd int)) {
	ql.datafd[fd] = cb
	mut ev := C.epoll_event{}
	ev.events = u32(C.EPOLLIN|C.EPOLLOUT|C.EPOLLET)
	ev.data.fd = fd
	C.fcntl(fd, C.F_SETFL, C.O_NONBLOCK)
	syscall.epoll_ctl(ql.epollfd, C.EPOLL_CTL_ADD, fd, mut ev)
}

@[inline]
pub fn (mut ql QevLoop) del_datafd(datafd int) {
	ql.unregist_fd << datafd
}

fn (mut ql QevLoop) unregister_datafd(datafd int) {
	mut ev := C.epoll_event{}
	syscall.epoll_ctl(ql.epollfd, C.EPOLL_CTL_DEL, datafd, mut ev)
	ql.datafd.delete(datafd)
	os.fd_close(datafd)
}

// timer does not have to finalyze
// and it can ne used
pub fn init_timer() ! {

}

pub fn add_oneshot_timer() {

}

pub fn add_sustain_timer() {

}

// Start main loop
pub fn (mut ql QevLoop) run() {
	if ql.sigwatch.len > 0 {
		ql.finalize_signal() or {  }
	}

	mut afdk := []int{cap: 1024}
	mut dfdk := []int{cap: 1024}

	for {
		mut eventbuf := []C.epoll_event{len: maxevent, cap: maxevent}
		mut ev := &eventbuf
		eventc := syscall.epoll_wait(ql.epollfd, mut ev, -1) or { 0 }
		if eventc < 0 {
			println('error, epoll_wait')
			exit(1)
		}
		for mli := 0; mli < eventc; mli++ {
			recv_fd := eventbuf[mli].data.fd
			afdk = ql.accepterfd.keys()
			dfdk = ql.datafd.keys()
			match true {
				recv_fd == ql.signalfd {
					sfds := C.signalfd_siginfo{}
					C.read(ql.signalfd, &sfds, sizeof(sfds))
					// don't confuse, sigwatch is SigWatcher.
					for i2, _ in ql.sigwatch {
						if int(ql.sigwatch[i2].signal) == int(sfds.ssi_signo) {
							ql.sigwatch[i2].callback()
						}
					}
				}
				recv_fd in afdk {
					cfd := C.accept(recv_fd, voidptr(0), 0)
					C.fcntl(cfd, C.F_SETFD, C.FD_CLOEXEC)
					ql.accepterfd[recv_fd](mut ql, cfd)
					if recv_fd in ql.unregist_fd {
						ql.unregister_accepterfd(recv_fd)
					}
				}
				recv_fd in dfdk {
					ql.datafd[recv_fd](mut ql, recv_fd)
					if recv_fd in ql.unregist_fd{
						ql.unregister_datafd(recv_fd)
					}
				}
				// recv_fd in ql.
				else {
					println('mystery')
					continue
				}
			}

			for i := ql.unregist_fd.len; i > ql.unregist_fd.len; i-- {
				fd := ql.unregist_fd[i]
				if fd in afdk {
					ql.unregister_accepterfd(fd)
				} else if fd in dfdk {
					ql.unregister_datafd(fd)
				}
				unsafe {
					free(fd)
				}
			}
			afdk.clear()
			dfdk.clear()
		}
		unsafe {
			eventbuf.free()
		}
	}
}
