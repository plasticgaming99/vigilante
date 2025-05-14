// quickev is a single threaded event loop librrary
// not recommended for using in network applications

module quickev

import os
import syscall

#include <unistd.h>
#include <signal.h>
#include <sys/epoll.h>
#include <sys/signalfd.h>

@[packed]
struct SignalWatcher {
	callback fn () @[required]
	signal   os.Signal
}

// free
fn (mut swt SignalWatcher) free() {
	unsafe {
		free(swt.callback)
		free(swt.signal)
	}
}

// loop structure.
@[packed]
struct QevLoop {
mut:
	sigwatch []SignalWatcher
	signalfd int
pub mut:
	epollfd int
}

pub fn init_loop() !QevLoop {
	ql := QevLoop{
		epollfd: syscall.epoll_create1(0) or { return err }
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
		os.signal_ignore(swt.signal)
	}
	sfd := syscall.signalfd(-1, ssfd, C.SFD_NONBLOCK)
	if sfd != 0 {
		error('failed to create signalfd')
	}
	ql.signalfd = sfd
	syscall.epoll_ctl(ql.epollfd, ql.signalfd)
}

/*pub fn (mut ql QevLoop) {

}*/

// Start main loop
pub fn (mut ql QevLoop) run() {
	for {
		sfds := C.signalfd_siginfo{}
		C.read(ql.signalfd, &sfds, sizeof(sfds))
		for i := 0; i < ql.sigwatch.len; i++ {
			if int(ql.sigwatch[i].signal) == int(sfds.ssi_signo) {
				ql.sigwatch[i].callback()
			}
		}
	}
}
