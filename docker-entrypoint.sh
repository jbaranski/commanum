#!/bin/bash
set -e

export NUM_ITERATIONS="${NUM_ITERATIONS:-1000000}"
OUTPUT_DIR="/output"

echo "========================================"
echo "  Commanum Valgrind Performance Testing"
echo "========================================"
echo "Reports will be written to ${OUTPUT_DIR}"
echo ""

# --- Lua Tests ---

echo "----------------------------------------"
echo "  Lua Valgrind Memcheck"
echo "----------------------------------------"
cd /app/lua
valgrind --tool=memcheck --leak-check=full luajit perf_test.lua 2>&1 | tee "${OUTPUT_DIR}/lua-memcheck-report.txt"
echo ""

echo "----------------------------------------"
echo "  Lua Valgrind Massif (Heap Profiler)"
echo "----------------------------------------"
valgrind --tool=massif --massif-out-file="${OUTPUT_DIR}/lua-massif.out" luajit perf_test.lua
ms_print "${OUTPUT_DIR}/lua-massif.out" | tee "${OUTPUT_DIR}/lua-massif-report.txt"
echo ""

echo "----------------------------------------"
echo "  Lua Valgrind Callgrind"
echo "----------------------------------------"
valgrind --tool=callgrind --callgrind-out-file="${OUTPUT_DIR}/lua-callgrind.out" luajit perf_test.lua
callgrind_annotate "${OUTPUT_DIR}/lua-callgrind.out" | tee "${OUTPUT_DIR}/lua-callgrind-report.txt"
echo ""

# --- Zig Tests ---

echo "----------------------------------------"
echo "  Zig Valgrind Memcheck"
echo "----------------------------------------"
cd /app
valgrind --tool=memcheck --leak-check=full ./zig/zig-out/bin/perf_test 2>&1 | tee "${OUTPUT_DIR}/zig-memcheck-report.txt"
echo ""

echo "----------------------------------------"
echo "  Zig Valgrind Massif (Heap Profiler)"
echo "----------------------------------------"
valgrind --tool=massif --massif-out-file="${OUTPUT_DIR}/zig-massif.out" ./zig/zig-out/bin/perf_test
ms_print "${OUTPUT_DIR}/zig-massif.out" | tee "${OUTPUT_DIR}/zig-massif-report.txt"
echo ""

echo "----------------------------------------"
echo "  Zig Valgrind Callgrind"
echo "----------------------------------------"
valgrind --tool=callgrind --callgrind-out-file="${OUTPUT_DIR}/zig-callgrind.out" ./zig/zig-out/bin/perf_test
callgrind_annotate "${OUTPUT_DIR}/zig-callgrind.out" | tee "${OUTPUT_DIR}/zig-callgrind-report.txt"
echo ""

# --- Go Tests ---

echo "----------------------------------------"
echo "  Go Valgrind Memcheck"
echo "----------------------------------------"
cd /app
valgrind --tool=memcheck --leak-check=full ./go/bin/perf_test 2>&1 | tee "${OUTPUT_DIR}/go-memcheck-report.txt"
echo ""

echo "----------------------------------------"
echo "  Go Valgrind Massif (Heap Profiler)"
echo "----------------------------------------"
valgrind --tool=massif --massif-out-file="${OUTPUT_DIR}/go-massif.out" ./go/bin/perf_test
ms_print "${OUTPUT_DIR}/go-massif.out" | tee "${OUTPUT_DIR}/go-massif-report.txt"
echo ""

echo "----------------------------------------"
echo "  Go Valgrind Callgrind"
echo "----------------------------------------"
valgrind --tool=callgrind --callgrind-out-file="${OUTPUT_DIR}/go-callgrind.out" ./go/bin/perf_test
callgrind_annotate "${OUTPUT_DIR}/go-callgrind.out" | tee "${OUTPUT_DIR}/go-callgrind-report.txt"
echo ""

echo "========================================"
echo "  All tests complete"
echo "========================================"
echo ""
echo "Reports in ${OUTPUT_DIR}:"
ls -lh "${OUTPUT_DIR}"
