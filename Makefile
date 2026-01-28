build:
	zig build --summary all

install:
	make build && cp zig-out/bin/commanum ~/.local/bin

install-lua:
	cp lua/commanum.lua ~/.local/bin/commanum-lua