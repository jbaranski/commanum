build:
	zig build --summary all

install:
	make build && cp zig-out/bin/commanum ~/.local/bin