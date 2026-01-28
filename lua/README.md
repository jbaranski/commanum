# Lua Performance Testing & Profiling

This directory contains the Lua implementation of `commanum` and performance testing tools.

## Quick Start

```bash
# Run the CLI
luajit lua/commanum.lua 1234567890

# Run basic performance test
make perf-lua
```

## Profiling Options

### Option 1: Basic Performance Test
```bash
make perf-lua
```

Runs the standard performance test with timing statistics. Output includes:
- Total benchmark time
- Per-operation average/min/max nanoseconds
- Throughput (ops/sec)

---

### Option 2: LuaJIT Verbose JIT Info (`-jv`)
```bash
make perf-lua-jv
```

Shows JIT compilation activity in real-time.

**How to read the output:**

```
[TRACE   1 perf_test.lua:73 loop]
[TRACE   2 (1/3) perf_test.lua:18 -> 1]
```

- `TRACE N` - Trace number N was compiled
- `loop` - A loop was compiled
- `(1/3)` - Side trace from trace 1, exit 3
- `->` - Trace links to another trace
- File:line shows where the trace starts

**What to look for:**
- Many traces = code is being JIT compiled (good)
- `NYI` (Not Yet Implemented) = feature falls back to interpreter (bad)
- `ABORT` = trace compilation failed
- Frequent re-traces of same location = unstable code path

---

### Option 3: LuaJIT Profiler (`-jp`)
```bash
make perf-lua-jp
```

Shows where time is spent. Requires LuaJIT built with profiler support.

**How to read the output:**

```
  45%  perf_test.lua:73    formatWithCommas
  30%  perf_test.lua:18    random_u64_string
  15%  [string "..."]:1    (main chunk)
  10%  (C)                 string.char
```

- Percentage = time spent in that location
- File:line = source location
- Function name or `(C)` for C functions

**What to look for:**
- Hotspots (high percentage) = optimize these first
- Unexpected C function calls = may indicate inefficient Lua code
- `(C)` dominance = most time in C extensions (usually good)

#### Option 3b: Flame Graph Output
```bash
make perf-lua-jp-flame
```

Generates `lua/perf_flame.txt` for flame graph visualization:
```bash
# Convert to SVG (requires FlameGraph tools)
flamegraph.pl lua/perf_flame.txt > flame.svg
```

---

### Option 4: Valgrind Massif (Heap Profiler)
```bash
make perf-lua-massif
```

Shows heap memory usage over time. **Linux only.**

**How to read the output:**

```
    MB
19.63^                                               #
     |                                              @#::
     |                                           @@@#::
     |                                        @@@@@@#::
     |                                     @@@@@@@@@#::
     |                                  @@@@@@@@@@@@#:::
     |                               @@@@@@@@@@@@@@@#:::
     |                            @@@@@@@@@@@@@@@@@@#::::
     |                         @@@@@@@@@@@@@@@@@@@@@#::::
     |                       @@@@@@@@@@@@@@@@@@@@@@@@#::::
     |                    @@@@@@@@@@@@@@@@@@@@@@@@@@@#:::::
     |                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#::::::
     |              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#:::::::
     |           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#::::::::
     |        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#:::::::::
   0 +--------------------------------------------------------------->Gi
     0                                                           1.234
```

- Y-axis = memory usage
- X-axis = time (instructions executed)
- `#` = peak memory points
- `@` = normal allocations
- `:` = stack memory

**Detailed breakdown shows:**
```
99.48% (20,000,000B) (heap allocation functions) malloc/new/...
->95.00% (19,000,000B) in 1000000 places: luaM_realloc_
  ->90.00%: formatWithCommas
```

**What to look for:**
- Peak memory usage (top of graph)
- Memory growth patterns (steady = leak possible)
- Allocation hotspots in the detailed section

#### Option 4b: Callgrind (Call Graph)
```bash
make perf-lua-callgrind
```

Generates detailed call graph data. View with:
```bash
kcachegrind lua/callgrind.out   # GUI viewer
# or
callgrind_annotate lua/callgrind.out  # Text output
```

**What to look for:**
- Inclusive vs Self time (self = time in function only)
- Call counts (high counts on expensive functions = problem)
- Call chains showing who calls what

---

### Option 5: Lua Memory Tracking (`collectgarbage`)
```bash
make perf-lua-mem
```

Uses Lua's built-in `collectgarbage("count")` for memory tracking.

**How to read the output:**

```
Initial memory: 45.23 KB
Memory after generation: 12045.67 KB
Memory used for numbers: 12000.44 KB

Memory Statistics:
------------------
Before benchmark:  12045.67 KB
Peak during run:   15234.89 KB
After benchmark:   12100.45 KB
Memory delta:      54.78 KB
Peak increase:     3189.22 KB

Memory Samples During Run:
--------------------------
  10% ( 100000): 12500.34 KB
  20% ( 200000): 13200.56 KB
  ...

Garbage Collection Info:
------------------------
After full GC: 12045.23 KB
Freed by GC:   55.22 KB
```

**What to look for:**
- **Memory delta** - How much memory the benchmark itself uses
- **Peak increase** - Temporary allocations during run
- **Freed by GC** - Objects created but not retained
- **Samples** - Memory growth pattern (should be flat for efficient code)

**Interpreting patterns:**
- Flat samples = efficient, minimal allocation
- Rising samples = creating objects that survive GC
- Sawtooth = creating then freeing many objects (GC overhead)
- Large peak vs delta = lots of temporary allocations

---

## Cleaning Up

```bash
make clean-prof
```

Removes generated profiling files (`massif.out`, `callgrind.out`, `perf_flame.txt`).

---

## Summary: Which Tool to Use

| Goal | Tool |
|------|------|
| Quick timing stats | `make perf-lua` |
| Check if JIT is working | `make perf-lua-jv` |
| Find CPU hotspots | `make perf-lua-jp` |
| Profile heap memory | `make perf-lua-massif` |
| Profile Lua-level memory | `make perf-lua-mem` |
| Full call graph analysis | `make perf-lua-callgrind` |
