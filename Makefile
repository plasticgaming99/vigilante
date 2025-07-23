CC = clang
LD = ld.lld
CFLAGS = -O3 -march=native -pipe -fclangir \
         -fno-plt  -fno-rtti \
         -flto=thin -fforce-emit-vtables -fwhole-program-vtables \
         -static-pie -fstack-protector -fPIC
         
LDFLAGS = -fPIE -static-pie -O3 -flto=full -fuse-ld=lld -fintegrated-as -fintegrated-cc1 -Wl,-O2,--lto-O3,--emit-relocs,--discard-none

all:
	v . -gc none -d no_segfault_handler -fast-math -cc "$(CC)" -cflags "$(CFLAGS)" -ldflags "$(LDFLAGS)"

prof-opt:
	v . -gc none -d no_segfault_handler -fast-math -cc "$(CC)" -cflags "$(CFLAGS) -fcs-profile-generate"
	./vigilante -s -d ./testfiles || true
	llvm-profdata merge --output=default.profdata default*.profraw
	v . -gc none -d no_segfault_handler -fast-math -cc "$(CC)" -cflags "$(CFLAGS) -fprofile-use=$(PWD)/default.profdata"
