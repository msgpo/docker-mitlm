ARG BUILD_FROM
FROM $BUILD_FROM

ARG MAKE_THREADS=8

COPY etc/qemu-arm-static /usr/bin/
COPY etc/qemu-aarch64-static /usr/bin/

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        automake autoconf-archive gfortran libtool

COPY download/mitlm-0.4.2/ /mitlm-0.4.2/

# Build mitlm
RUN cd /mitlm-0.4.2 && \
    ./autogen.sh --prefix=/build && \
    make -j $MAKE_THREADS && \
    make install

RUN mkdir -p /mitlm/bin && \
    mkdir -p /mitlm/lib && \
    cp /build/bin/* /mitlm/bin/ && \
    cp /build/lib/libmitlm.so.1 /mitlm/lib/

# Copy dependencies
RUN ldd /mitlm/bin/* /mitlm/lib/*.so* | grep '=> /' | grep 'libgfortran' | awk '{ print $3 }' | xargs -n1 -I {} cp -vL '{}' /mitlm/lib/