ARG BUILD_FROM
FROM $BUILD_FROM

ARG MAKE_THREADS=8

COPY etc/qemu-arm-static /usr/bin/
COPY etc/qemu-aarch64-static /usr/bin/

RUN apt-get update
RUN apt-get install -y --no-install-recommends \
        build-essential \
        automake autoconf-archive gfortran libtool

COPY download/mitlm-0.4.2.tar.xz /

RUN cd / && tar -xvf /mitlm-0.4.2.tar.xz

# Build mitlm
RUN cd /mitlm-0.4.2 && \
    ./autogen.sh && \
    ./configure --prefix=/build && \
    make -j $MAKE_THREADS && \
    make install

RUN mkdir -p /mitlm/bin && \
    mkdir -p /mitlm/lib && \
    cp /build/bin/* /mitlm/bin/ && \
    cp /build/lib/*.so* /mitlm/lib/
    