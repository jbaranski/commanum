package main

import (
	crand "crypto/rand"
	"encoding/binary"
	"flag"
	"fmt"
	"math/rand/v2"
	"os"
	"runtime"
	"runtime/pprof"
	"runtime/trace"
	"strconv"
	"time"

	"commanum"
)

const defaultNumIterations = 1_000_000

var (
	cpuprofile = flag.String("cpuprofile", "", "write CPU profile to file")
	memprofile = flag.String("memprofile", "", "write memory profile to file")
	tracefile  = flag.String("trace", "", "write execution trace to file")
)

type numEntry struct {
	buf [commanum.MaxDigits]byte
	len uint8
}

func main() {
	flag.Parse()

	// Start CPU profiling if requested
	if *cpuprofile != "" {
		f, err := os.Create(*cpuprofile)
		if err != nil {
			fmt.Fprintf(os.Stderr, "could not create CPU profile: %v\n", err)
			os.Exit(1)
		}
		defer f.Close()
		if err := pprof.StartCPUProfile(f); err != nil {
			fmt.Fprintf(os.Stderr, "could not start CPU profile: %v\n", err)
			os.Exit(1)
		}
		defer pprof.StopCPUProfile()
	}

	// Start execution trace if requested
	if *tracefile != "" {
		f, err := os.Create(*tracefile)
		if err != nil {
			fmt.Fprintf(os.Stderr, "could not create trace: %v\n", err)
			os.Exit(1)
		}
		defer f.Close()
		if err := trace.Start(f); err != nil {
			fmt.Fprintf(os.Stderr, "could not start trace: %v\n", err)
			os.Exit(1)
		}
		defer trace.Stop()
	}

	numIterations := defaultNumIterations
	if v := os.Getenv("NUM_ITERATIONS"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			numIterations = n
		}
	}

	fmt.Println("Go Performance Test")
	fmt.Println("====================")
	fmt.Printf("Iterations: %d\n", numIterations)
	fmt.Printf("Range: 0 to %d (max u64)\n\n", uint64(^uint64(0)))

	// Initialize PRNG with crypto seed
	var seedBuf [16]byte
	crand.Read(seedBuf[:])
	seed1 := binary.LittleEndian.Uint64(seedBuf[:8])
	seed2 := binary.LittleEndian.Uint64(seedBuf[8:])
	rng := rand.New(rand.NewPCG(seed1, seed2))

	// Pre-generate all random number strings
	fmt.Printf("Generating %d random number strings...\n", numIterations)
	genStart := time.Now()

	entries := make([]numEntry, numIterations)
	for i := range entries {
		n := rng.Uint64()
		s := strconv.AppendUint(entries[i].buf[:0], n, 10)
		entries[i].len = uint8(len(s))
	}

	genElapsed := time.Since(genStart)
	fmt.Printf("Generation time: %.3f ms\n\n", float64(genElapsed.Nanoseconds())/1e6)

	fmt.Println("Running formatting benchmark...")
	benchStart := time.Now()

	for i := 0; i < numIterations; i++ {
		e := &entries[i]
		commanum.FormatWithCommas(e.buf[:e.len])
	}

	benchElapsed := time.Since(benchStart)

	// Calculate statistics
	totalNs := float64(benchElapsed.Nanoseconds())
	totalMs := totalNs / 1e6
	avgNs := totalNs / float64(numIterations)
	opsPerSec := float64(numIterations) / (totalMs / 1000.0)

	// Print results
	fmt.Println("\nResults:")
	fmt.Println("--------")
	fmt.Printf("Total benchmark time:  %.3f ms\n", totalMs)
	fmt.Printf("Average per operation: %.1f ns\n", avgNs)
	fmt.Printf("Throughput: %.0f ops/sec\n", opsPerSec)

	// Write memory profile if requested
	if *memprofile != "" {
		runtime.GC()
		f, err := os.Create(*memprofile)
		if err != nil {
			fmt.Fprintf(os.Stderr, "could not create memory profile: %v\n", err)
			os.Exit(1)
		}
		defer f.Close()
		if err := pprof.WriteHeapProfile(f); err != nil {
			fmt.Fprintf(os.Stderr, "could not write memory profile: %v\n", err)
			os.Exit(1)
		}
	}
}
