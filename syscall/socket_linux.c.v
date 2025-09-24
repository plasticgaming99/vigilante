module syscall

import net

#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <stdio.h>

//fn C.socket (int, int, int) int

struct C.sockaddr_un{
	sun_family int
	sun_path [108]u8
}

//fn C.unlink(&u8) int

struct C.sockaddr {
	sa_family int
	sa_data [14]u8
};

fn C.bind (int, &C.sockaddr, u32) int;

pub fn create_unix_domain_socket(path string) !int {
	s := C.socket(net.AddrFamily.unix, net.SocketType.seqpacket, 0)
	if s < 0 {
		return error("failed to create socket")
	}

    mut addr := C.sockaddr_un{}
    addr.sun_family = C.AF_UNIX
    for i, c in path.bytes() {
        addr.sun_path[i] = c
    }

	C.unlink(path.str)

	ret := C.bind(s, voidptr(&addr), sizeof(C.sockaddr_un))
    if ret != 0 {
        return error("bind failed")
	}

	C.listen(s, 5)

	return s
}

pub fn connect_unix_domain_socket(path string) !int {
	s := C.socket(net.AddrFamily.unix, net.SocketType.seqpacket, 0)
	if s < 0 {
		return error("failed to create socket")
	}

    mut addr := C.sockaddr_un{}
    addr.sun_family = 1
    for i, c in path.bytes() {
        addr.sun_path[i] = c
    }

	ret := C.connect(s, voidptr(&addr), sizeof(C.sockaddr_un))
	//println(c_error_number_str(C.errno))
    if ret != 0 {
		C.close(s)
        return error("connect failed")
	}

	return s
}
