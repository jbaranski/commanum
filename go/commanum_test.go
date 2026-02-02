package commanum

import "testing"

var (
	sinkBuf [MaxFormattedLen]byte
	sinkN   int
)

func BenchmarkFormatWithCommas_MaxU64(b *testing.B) {
	input := []byte("18446744073709551615")
	for i := 0; i < b.N; i++ {
		sinkBuf, sinkN, _ = FormatWithCommas(input)
	}
}

func BenchmarkFormatWithCommas_Medium(b *testing.B) {
	input := []byte("1234567890")
	for i := 0; i < b.N; i++ {
		sinkBuf, sinkN, _ = FormatWithCommas(input)
	}
}

func BenchmarkFormatWithCommas_Small(b *testing.B) {
	input := []byte("12345")
	for i := 0; i < b.N; i++ {
		sinkBuf, sinkN, _ = FormatWithCommas(input)
	}
}

func BenchmarkFormatWithCommas_Single(b *testing.B) {
	input := []byte("7")
	for i := 0; i < b.N; i++ {
		sinkBuf, sinkN, _ = FormatWithCommas(input)
	}
}

func TestFormatWithCommas_ZeroAllocs(t *testing.T) {
	input := []byte("18446744073709551615")
	allocs := testing.AllocsPerRun(1000, func() {
		sinkBuf, sinkN, _ = FormatWithCommas(input)
	})
	if allocs != 0 {
		t.Errorf("expected 0 allocations, got %f", allocs)
	}
}

func TestFormatWithCommas_Correctness(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		{"0", "0"},
		{"1", "1"},
		{"12", "12"},
		{"123", "123"},
		{"1234", "1,234"},
		{"12345", "12,345"},
		{"123456", "123,456"},
		{"1234567", "1,234,567"},
		{"1234567890", "1,234,567,890"},
		{"18446744073709551615", "18,446,744,073,709,551,615"},
	}
	for _, tt := range tests {
		buf, n, err := FormatWithCommas([]byte(tt.input))
		if err != nil {
			t.Errorf("FormatWithCommas(%q) returned error: %v", tt.input, err)
			continue
		}
		if string(buf[:n]) != tt.expected {
			t.Errorf("FormatWithCommas(%q) = %q, want %q", tt.input, string(buf[:n]), tt.expected)
		}
	}
}

func TestFormatWithCommas_InvalidInput(t *testing.T) {
	_, _, err := FormatWithCommas([]byte("123abc"))
	if err != ErrInvalidInput {
		t.Errorf("expected ErrInvalidInput, got %v", err)
	}
}
