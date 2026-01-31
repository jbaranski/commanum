FROM amazonlinux:2023

RUN dnf update -y && dnf install -y \
    gcc make git tar xz wget \
    cmake \
    valgrind \
    && dnf clean all

# Install Tarantool's LuaJIT fork (includes misc.memprof memory profiler)
# https://github.com/tarantool/luajit
RUN git clone --depth 1 -b tarantool https://github.com/tarantool/luajit.git /tmp/luajit && \
    cd /tmp/luajit && \
    cmake -B build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build && \
    cmake --install build && \
    ldconfig && \
    rm -rf /tmp/luajit

# Install Zig 0.15.1 (detect architecture)
ARG TARGETARCH
RUN ZIG_ARCH=$(if [ "$TARGETARCH" = "arm64" ]; then echo "aarch64"; else echo "x86_64"; fi) && \
    wget -q "https://ziglang.org/download/0.15.1/zig-${ZIG_ARCH}-linux-0.15.1.tar.xz" -O /tmp/zig.tar.xz && \
    tar xf /tmp/zig.tar.xz -C /opt && \
    ln -s /opt/zig-${ZIG_ARCH}-linux-0.15.1/zig /usr/local/bin/zig && \
    rm /tmp/zig.tar.xz

WORKDIR /app

COPY . .

# Pre-build zig perf test binary
RUN cd zig && zig build

VOLUME /output

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
