CC = clang
LD = ld.lld
CFLAGS = -O3 -march=skylake -mtune=generic -pipe -ffunction-sections -fdata-sections \
         -flto=full -fforce-emit-vtables -fwhole-program-vtables -fvisibility=hidden \
         -fomit-frame-pointer -static \
         
         
LDFLAGS = -O3 -fuse-ld=lld -fintegrated-as -fintegrated-cc1 -Wl,--icf=safe,--gc-sections,--as-needed,--lto-O3

all:
	v . -prod -d no_segfault_handler -fast-math -cc "$(CC)" -cflags "$(CFLAGS)" -ldflags "$(LDFLAGS)"
