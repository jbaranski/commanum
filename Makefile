FLAMEGRAPH_PL ?= flamegraph.pl

build:
	cd zig && zig build --summary all

install:
	make build && cp zig/zig-out/bin/commanum ~/.local/bin

run-lua:
	luajit lua/commanum.lua $(args) # args=1000

install-lua:
	cp lua/commanum.lua ~/.local/bin/commanum-lua

# Performance test (basic)
perf-zig:
	cd zig && zig build perf

perf-lua:
	cd lua && luajit perf_test.lua

# Profiling options - see README.md for how to interpret results

# Option 2: LuaJIT verbose JIT compilation info
perf-lua-jv:
	cd lua && luajit -jv perf_test.lua

# Option 2b: LuaJIT detailed JIT dump (bytecode, IR, machine code per trace)
perf-lua-jdump:
	cd lua && luajit -jdump perf_test.lua

# Option 3: LuaJIT profiler (requires LuaJIT built with profiler support)
perf-lua-jp:
	cd lua && luajit -jp=vl perf_test.lua

# Option 3b: LuaJIT profiler with flame graph output (requires FlameGraph: https://github.com/brendangregg/FlameGraph)
perf-lua-jp-flame:
	cd lua && luajit -jp=F,perf_flame.txt perf_test.lua && $(FLAMEGRAPH_PL) perf_flame.txt > perf_flame.svg && echo "Flame graph SVG written to lua/perf_flame.svg"

# Option 4: Memory tracking using collectgarbage (built into perf_test)
perf-lua-mem:
	cd lua && luajit -e "package.path='./?.lua;'..package.path" -e "require('perf_test_mem')"

# Docker perf testing with valgrind
docker-perf-valgrind:
	rm -rf output && docker build -t commanum-perf . && mkdir -p output && docker run --rm -v ./output:/output commanum-perf

# View valgrind results in GUI (requires: brew install qcachegrind massif-visualizer)
view-callgrind:
	qcachegrind output/zig-callgrind.out

view-massif:
	massif-visualizer output/zig-massif.out

# Clean profiling artifacts
clean-prof:
	rm -f lua/perf_flame.txt lua/perf_flame.svg
