build:
	zig build --summary all

install:
	make build && cp zig-out/bin/commanum ~/.local/bin

run-lua:
	luajit lua/commanum.lua $(args) # args=1000

install-lua:
	cp lua/commanum.lua ~/.local/bin/commanum-lua

perf-zig:
	zig build perf

perf-lua:
	cd lua && luajit perf_test.lua && cd ../

perf-all:
	@echo "=== Zig Performance Test ===" && zig build perf && echo "" && echo "=== Lua Performance Test ===" && cd lua && lua perf_test.lua