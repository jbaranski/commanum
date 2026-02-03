FLAMEGRAPH_PL ?= flamegraph.pl

build:
	cd zig && zig build --summary all

install:
	make build && cp zig/zig-out/bin/commanum ~/.local/bin

run-lua:
	luajit lua/commanum.lua $(args) # args=1000

install-lua:
	cp lua/commanum.lua ~/.local/bin/commanum-lua

# Go build targets
build-go:
	cd go && mkdir -p bin && CGO_ENABLED=0 go build -o bin/commanum ./cmd/commanum && CGO_ENABLED=0 go build -o bin/perf_test ./cmd/perf_test

install-go:
	cd go && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o ~/.local/bin/commanum-go ./cmd/commanum

run-go:
	cd go && go run ./cmd/commanum $(args) # args=1000

# Performance test (basic)
perf-zig:
	cd zig && zig build perf

perf-lua:
	cd lua && luajit perf_test.lua

perf-go:
	cd go && mkdir -p bin && CGO_ENABLED=0 go build -o bin/perf_test ./cmd/perf_test && ./bin/perf_test

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

# Option 5: Per-line memory allocation profiler (debug.sethook + collectgarbage, works with any LuaJIT)
perf-lua-memprof:
	cd lua && luajit perf_test_memprof.lua

# Go profiling options

# Go benchmark tests with memory stats
perf-go-bench:
	cd go && go test -bench=. -benchmem -count=3

# Go CPU profiling with pprof (text top functions report)
perf-go-cpuprof:
	cd go && mkdir -p bin && CGO_ENABLED=0 go build -o bin/perf_test ./cmd/perf_test && ./bin/perf_test -cpuprofile=cpu.prof && go tool pprof -top bin/perf_test cpu.prof

# Go CPU profile interactive web UI (flame graph, call graph, source view at :8080)
perf-go-cpuprof-flame:
	cd go && mkdir -p bin && CGO_ENABLED=0 go build -o bin/perf_test ./cmd/perf_test && ./bin/perf_test -cpuprofile=cpu.prof && go tool pprof -http=:8080 bin/perf_test cpu.prof

# Go memory profiling with pprof (text top allocators report)
perf-go-memprof:
	cd go && mkdir -p bin && CGO_ENABLED=0 go build -o bin/perf_test ./cmd/perf_test && ./bin/perf_test -memprofile=mem.prof && go tool pprof -top bin/perf_test mem.prof

# Go execution trace (view with: go tool trace go/trace.out)
perf-go-trace:
	cd go && mkdir -p bin && CGO_ENABLED=0 go build -o bin/perf_test ./cmd/perf_test && ./bin/perf_test -trace=trace.out && echo "Trace written to go/trace.out - view with: go tool trace go/trace.out"

# Go GC statistics via GODEBUG
perf-go-gcstats:
	cd go && mkdir -p bin && CGO_ENABLED=0 go build -o bin/perf_test ./cmd/perf_test && GODEBUG=gctrace=1 ./bin/perf_test

# Docker perf testing with valgrind
docker-perf-valgrind:
	rm -rf output && docker build -t commanum-perf . && mkdir -p output && docker run --rm -v ./output:/output commanum-perf

# View callgrind results in GUI (requires: brew install qcachegrind)
view-callgrind-zig:
	qcachegrind output/zig-callgrind.out

view-callgrind-lua:
	qcachegrind output/lua-callgrind.out

# Clean profiling artifacts
clean-prof:
	rm -f lua/perf_flame.txt lua/perf_flame.svg go/cpu.prof go/mem.prof go/trace.out
