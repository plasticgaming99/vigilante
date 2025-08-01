// quickev is a single threaded event loop librrary
// not recommended for using in network applications
// only epoll/linux-fds is available currently

module quickev

import os
import syscall
import net.unix

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
struct QevLoop {
mut:
	sigwatch      []SignalWatcher
	signalfd_mask syscall.SigSetFd
	sfdepollev    C.epoll_event
	signalfd      int
	generalfd     []int
	generalfdcb   map[int]fn ([]byte)
	epollfd       int
}

pub fn init_loop() !QevLoop {
	mut ql := QevLoop{
		epollfd: syscall.epoll_create1(C.O_CLOEXEC) or { return err }
	}
	return ql
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

// This method registers signalfd
// please do not add signal to watch after this method
pub fn (mut ql QevLoop) finalize_signal() ! {
	mut ssfd := syscall.new_sigset_fd()
	for swt in ql.sigwatch {
		ssfd.add(int(swt.signal))
	}
	syscall.sigprocmask(C.SIG_BLOCK, &ssfd.val[0], unsafe { nil })
	sfd := syscall.signalfd(-1, ssfd, C.SFD_NONBLOCK | C.O_CLOEXEC)
	println(os.posix_get_error_msg(C.errno))
	if sfd == -1 {
		error('failed to create signalfd')
	}
	ql.signalfd = sfd
	ql.signalfd_mask = ssfd
	ql.sfdepollev.events = u32(C.EPOLLIN)
	mut e_ev := &ql.sfdepollev
	syscall.epoll_ctl(ql.epollfd, C.EPOLL_CTL_ADD, ql.signalfd, mut e_ev)
}

pub fn (ql &QevLoop) get_signalfd() int {
	return ql.signalfd
}

pub fn (ql &QevLoop) get_epollfd() int {
	return ql.epollfd
}

// Start main loop
pub fn (ql &QevLoop) run() {
	for {
		mut eventbuf := [C.epoll_event{}].repeat(maxevent)
		mut ev := &eventbuf
		eventc := syscall.epoll_wait(ql.epollfd, mut ev, -1) or { 0 }
		if eventc < 0 {
			println('error, epoll_wait')
			exit(1)
		}
		for i := 0; i < eventc; i++ {
			recv_fd := eventbuf[i].data.fd
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
				// recv_fd in ql.
				else {
					println('mystery')
					continue
				}
			}
		}
	}
}
