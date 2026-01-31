FROM amazonlinux:2023

RUN dnf update -y && dnf install -y \
    gcc make git tar xz wget \
    valgrind \
    && dnf clean all

# Install LuaJIT from source
RUN git clone --depth 1 https://github.com/LuaJIT/LuaJIT.git /tmp/luajit && \
    cd /tmp/luajit && \
    make && make install && \
    ldconfig && \
    rm -rf /tmp/luajit

# Install Zig 0.14.0 (detect architecture)
ARG TARGETARCH
RUN ZIG_ARCH=$(if [ "$TARGETARCH" = "arm64" ]; then echo "aarch64"; else echo "x86_64"; fi) && \
    wget -q "https://ziglang.org/download/0.14.0/zig-linux-${ZIG_ARCH}-0.14.0.tar.xz" -O /tmp/zig.tar.xz && \
    tar xf /tmp/zig.tar.xz -C /opt && \
    ln -s /opt/zig-linux-${ZIG_ARCH}-0.14.0/zig /usr/local/bin/zig && \
    rm /tmp/zig.tar.xz

WORKDIR /app

COPY . .

# Pre-build zig perf test binary
RUN zig build

VOLUME /output

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
