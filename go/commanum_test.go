package commanum

import "testing"

var sink []byte

func BenchmarkFormatWithCommas_MaxU64(b *testing.B) {
	input := []byte("18446744073709551615")
	var buf [MaxLen]byte
	for i := 0; i < b.N; i++ {
		sink, _ = FormatWithCommas(input, buf[:])
	}
}

func BenchmarkFormatWithCommas_Medium(b *testing.B) {
	input := []byte("1234567890")
	var buf [MaxLen]byte
	for i := 0; i < b.N; i++ {
		sink, _ = FormatWithCommas(input, buf[:])
	}
}

func BenchmarkFormatWithCommas_Small(b *testing.B) {
	input := []byte("12345")
	var buf [MaxLen]byte
	for i := 0; i < b.N; i++ {
		sink, _ = FormatWithCommas(input, buf[:])
	}
}

func BenchmarkFormatWithCommas_Single(b *testing.B) {
	input := []byte("7")
	var buf [MaxLen]byte
	for i := 0; i < b.N; i++ {
		sink, _ = FormatWithCommas(input, buf[:])
	}
}

func TestFormatWithCommas_ZeroAllocs(t *testing.T) {
	input := []byte("18446744073709551615")
	var buf [MaxLen]byte
	allocs := testing.AllocsPerRun(1000, func() {
		sink, _ = FormatWithCommas(input, buf[:])
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
	var buf [MaxLen]byte
	for _, tt := range tests {
		result, err := FormatWithCommas([]byte(tt.input), buf[:])
		if err != nil {
			t.Errorf("FormatWithCommas(%q) returned error: %v", tt.input, err)
			continue
		}
		if string(result) != tt.expected {
			t.Errorf("FormatWithCommas(%q) = %q, want %q", tt.input, result, tt.expected)
		}
	}
}

func TestFormatWithCommas_InvalidInput(t *testing.T) {
	var buf [MaxLen]byte
	_, err := FormatWithCommas([]byte("123abc"), buf[:])
	if err != ErrInvalidInput {
		t.Errorf("expected ErrInvalidInput, got %v", err)
	}
}
