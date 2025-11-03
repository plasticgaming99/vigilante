@[manualfree]
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
	match svcname.after('.') {
		'target' {
			println('[reached] ${svcname}')
		}
		'service' {
			println('[startng] ${svcname}')
		}
		'mount' {
			println('[mounted] ${svcname}')
		}
		else {
			println('[unknown] ${svcname}')
		}
	}
	unsafe {
		aft.free()
	}
}

pub fn logsimple_started(svcname string) {
	aft := svcname.after('.')
	match svcname.after('.') {
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
	unsafe {
		aft.free()
	}
}
