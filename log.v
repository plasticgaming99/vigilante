module main

// logger???
// like [  OK  ]?
// [*     ]
// [**    ]
// [ ***  ]
// [  *** ]
// [   ***]
// [    **]
// [     *]
// [FAILED]

pub fn logsimple_start(svcname string) {
	aft := svcname.after('.')
	match aft {
		'target' {
			println('[reached] ${svcname}')
		}
		'service' {
			println('          starting ${svcname}')
		}
		'mount' {
			println('[mounted] ${svcname}')
		}
		else {
			println('[unknown] ${svcname}')
		}
	}
}

pub fn logsimple_started(svcname string) {
	aft := svcname.after('.')
	match aft {
		'target' {
			println('[reached] ${svcname}')
		}
		'service' {
			println('[started] ${svcname}')
		}
		'mount' {
			println('[mounted] ${svcname}')
		}
		else {
			println('[unknown] ${svcname}')
		}
	}
}

pub fn logsimple_stop(svcname string) {
	aft := svcname.after('.')
	match aft {
		'target' {
			println('[stoppng] ${svcname}')
		}
		'service' {
			println('[stoppng] ${svcname}')
		}
		'mount' {
			println('[umnting] ${svcname}')
		}
		else {
			println('[unknown] ${svcname}')
		}
	}
}

pub fn logsimple_stopped(svcname string) {
	aft := svcname.after('.')
	match aft {
		'target' {
			println('[stopped] ${svcname}')
		}
		'service' {
			println('[stopped] ${svcname}')
		}
		'mount' {
			println('[umonted] ${svcname}')
		}
		else {
			println('[unknown] ${svcname}')
		}
	}
}