package main

import (
	"commanum"
	"flag"
	"fmt"
	"math/rand"
	"os"
	"runtime"
	"runtime/pprof"
	"runtime/trace"
	"strconv"
	"time"
)

const DefaultNumIterations = 1_000_000

func getNumIterations() int {
	if val := os.Getenv("NUM_ITERATIONS"); val != "" {
		if n, err := strconv.Atoi(val); err == nil {
			return n
		}
	}
	return DefaultNumIterations
}

func main() {
	cpuprofile := flag.String("cpuprofile", "", "write cpu profile to file")
	memprofile := flag.String("memprofile", "", "write memory profile to file")
	traceFile := flag.String("trace", "", "write execution trace to file")
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
	if *traceFile != "" {
		f, err := os.Create(*traceFile)
		if err != nil {
			fmt.Fprintf(os.Stderr, "could not create trace file: %v\n", err)
			os.Exit(1)
		}
		defer f.Close()
		if err := trace.Start(f); err != nil {
			fmt.Fprintf(os.Stderr, "could not start trace: %v\n", err)
			os.Exit(1)
		}
		defer trace.Stop()
	}

	numIterations := getNumIterations()

	fmt.Println("Go Performance Test")
	fmt.Println("===================")
	fmt.Printf("Iterations: %d\n", numIterations)
	fmt.Printf("Range: 0 to %d (max uint64)\n\n", uint64(1<<64-1))

	// Initialize random number generator
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))

	// Pre-generate all random number strings
	fmt.Printf("Generating %d random number strings...\n", numIterations)
	genStart := time.Now()

	numbers := make([]string, numIterations)
	for i := 0; i < numIterations; i++ {
		numbers[i] = strconv.FormatUint(rng.Uint64(), 10)
	}

	genElapsed := time.Since(genStart)
	fmt.Printf("Generation time: %.3f ms\n\n", float64(genElapsed.Nanoseconds())/1_000_000.0)

	// formatWithCommas benchmark
	fmt.Println("Running formatting benchmark...")

	benchStart := time.Now()

	for i := 0; i < numIterations; i++ {
		_, _ = commanum.FormatWithCommas(numbers[i])
	}

	benchElapsed := time.Since(benchStart)
	totalNs := benchElapsed.Nanoseconds()

	totalMs := float64(totalNs) / 1_000_000.0
	avgNs := float64(totalNs) / float64(numIterations)
	opsPerSec := float64(numIterations) / (totalMs / 1000.0)

	fmt.Println("\nformatWithCommas Results:")
	fmt.Println("------------------------")
	fmt.Printf("Total benchmark time:  %.3f ms\n", totalMs)
	fmt.Printf("Average per operation: %.1f ns\n", avgNs)
	fmt.Printf("Throughput: %.0f ops/sec\n", opsPerSec)

	// numberToWords benchmark
	fmt.Println("\nRunning numberToWords benchmark...")

	wordsStart := time.Now()

	for i := 0; i < numIterations; i++ {
		_ = commanum.NumberToWords(numbers[i])
	}

	wordsElapsed := time.Since(wordsStart)
	wordsNs := wordsElapsed.Nanoseconds()

	wordsMs := float64(wordsNs) / 1_000_000.0
	wordsAvgNs := float64(wordsNs) / float64(numIterations)
	wordsOps := float64(numIterations) / (wordsMs / 1000.0)

	fmt.Println("\nnumberToWords Results:")
	fmt.Println("---------------------")
	fmt.Printf("Total benchmark time:  %.3f ms\n", wordsMs)
	fmt.Printf("Average per operation: %.1f ns\n", wordsAvgNs)
	fmt.Printf("Throughput: %.0f ops/sec\n", wordsOps)

	// Write memory profile if requested
	if *memprofile != "" {
		f, err := os.Create(*memprofile)
		if err != nil {
			fmt.Fprintf(os.Stderr, "could not create memory profile: %v\n", err)
			os.Exit(1)
		}
		defer f.Close()
		runtime.GC()
		if err := pprof.WriteHeapProfile(f); err != nil {
			fmt.Fprintf(os.Stderr, "could not write memory profile: %v\n", err)
			os.Exit(1)
		}
	}
}
