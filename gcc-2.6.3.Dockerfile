FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y build-essential gcc gcc-multilib wget

WORKDIR /work
RUN wget https://mirrors.slackware.com/slackware/slackware-2.2.0/source/d/gcc/gcc-2.6.3.tar.gz
RUN tar xzf gcc-2.6.3.tar.gz

WORKDIR /work/gcc-2.6.3
COPY patches /work/patches
RUN sed -i -- 's/include <varargs.h>/include <stdarg.h>/g' *.c

RUN patch -u -p1 obstack.h -i ../patches/obstack-2.7.2.h.patch
RUN patch -u -p1 sdbout.c -i ../patches/sdbout-2.6.3.c.patch
RUN patch -u -p1 config/mips/mips.h -i ../patches/mipsel-2.6.patch

RUN ./configure \
    --target=mips-linux-gnu \
    --prefix=/opt/cross \
    --with-endian-little \
    --with-gnu-as \
    --host=i386-pc-linux \
    --build=i386-pc-linux

RUN make cpp cc1 xgcc cc1plus g++ CFLAGS="-std=gnu89 -m32 -static -Dbsd4_4 -Dmips" || true

COPY tests /work/tests
RUN ./cc1 -quiet -O2 /work/tests/little_endian.c && grep -E 'lbu\s\$2,0\(\$4\)' /work/tests/little_endian.s

COPY entrypoint.sh /work/
RUN chmod +x /work/entrypoint.sh
CMD [ "/work/entrypoint.sh" ]
