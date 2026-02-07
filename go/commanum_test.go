package commanum

import (
	"math/rand"
	"strconv"
	"testing"
	"time"
)

func BenchmarkFormatWithCommas(b *testing.B) {
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))
	numbers := make([]string, b.N)
	for i := 0; i < b.N; i++ {
		numbers[i] = strconv.FormatUint(rng.Uint64(), 10)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = FormatWithCommas(numbers[i])
	}
}

func BenchmarkNumberToWords(b *testing.B) {
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))
	numbers := make([]string, b.N)
	for i := 0; i < b.N; i++ {
		numbers[i] = strconv.FormatUint(rng.Uint64(), 10)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = NumberToWords(numbers[i])
	}
}
