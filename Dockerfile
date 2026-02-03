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

# Install Zig 0.15.1 (detect architecture)
ARG TARGETARCH
RUN ZIG_ARCH=$(if [ "$TARGETARCH" = "arm64" ]; then echo "aarch64"; else echo "x86_64"; fi) && \
    wget -q "https://ziglang.org/download/0.15.1/zig-${ZIG_ARCH}-linux-0.15.1.tar.xz" -O /tmp/zig.tar.xz && \
    tar xf /tmp/zig.tar.xz -C /opt && \
    ln -s /opt/zig-${ZIG_ARCH}-linux-0.15.1/zig /usr/local/bin/zig && \
    rm /tmp/zig.tar.xz

# Install Go (detect architecture)
RUN GO_ARCH=$(if [ "$TARGETARCH" = "arm64" ]; then echo "arm64"; else echo "amd64"; fi) && \
    wget -q "https://go.dev/dl/go1.25.6.linux-${GO_ARCH}.tar.gz" -O /tmp/go.tar.gz && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

WORKDIR /app

COPY . .

# Pre-build zig perf test binary
RUN cd zig && zig build

# Pre-build go perf test binary (static for valgrind)
RUN cd go && mkdir -p bin && CGO_ENABLED=0 go build -o bin/perf_test ./cmd/perf_test

VOLUME /output

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
