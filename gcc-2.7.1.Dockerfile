FROM ubuntu:focal as build
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y build-essential gcc gcc-multilib wget

WORKDIR /work
RUN wget http://ftp.sunet.se/mirror/archive/ftp.sunet.se/pub/vendor/sun/freeware/SOURCES/gcc-2.7.1.tar.gz
RUN tar xzf gcc-2.7.1.tar.gz

WORKDIR /work/gcc-2.7.1
COPY patches /work/patches
RUN sed -i -- 's/include <varargs.h>/include <stdarg.h>/g' *.c

RUN patch -u -p1 obstack.h -i ../patches/obstack-2.7.2.h.patch
RUN patch -u -p1 configure -i ../patches/configure.patch
RUN patch -u -p1 config.sub -i ../patches/config.sub.patch
RUN patch -u -p1 config/mips/mips.h -i ../patches/mipsel-2.7.patch

RUN ./configure \
    --target=mips-linux-gnu \
    --prefix=/opt/cross \
    --with-endian-little \
    --with-gnu-as \
    --disable-gprof \
    --disable-gdb \
    --disable-werror \
    --host=i386-pc-linux \
    --build=i386-pc-linux

RUN make -j cpp cc1 xgcc cc1plus g++ CFLAGS="-std=gnu89 -m32 -static"

COPY tests /work/tests
RUN ./cc1 -quiet -O2 /work/tests/little_endian.c && grep -E 'lbu\s\$2,0\(\$4\)' /work/tests/little_endian.s

RUN mv xgcc gcc
RUN mkdir /build && cp cpp cc1 gcc cc1plus g++ /build/

FROM scratch AS export
COPY --from=build /build/* .
