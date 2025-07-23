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

pub fn logsimple(svcname string) {
	match svcname.after('.') {
		'target' {
			println('reached target ${svcname}')
		}
		'service' {
			println('starting service ${svcname}')
		}
		'mount' {
			println('mounted ${svcname}')
		}
		else {
			println('ran unknown ${svcname}')
		}
	}
}
