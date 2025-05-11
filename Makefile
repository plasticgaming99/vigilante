CC = clang
LD = ld.lld
CFLAGS = -O2 -march=skylake -mtune=generic -pipe -ffunction-sections -fdata-sections \
         -flto=full -faddrsig -fforce-emit-vtables -fomit-frame-pointer -static
         #-nostdinc --sysroot=/usr/lib/musl -isystem=/usr/lib/musl/include
         #-I/usr/lib/musl/include -I/usr/include
         
LDFLAGS = -O3 -fuse-ld=lld -fintegrated-as -fintegrated-cc1 -Wl,--icf=safe,--gc-sections,--as-needed

all:
	v . -prod -d no_segfault_handler -fast-math -cc "$(CC)" -cflags "$(CFLAGS)" -ldflags "$(LDFLAGS)"
