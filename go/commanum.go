package commanum

import "errors"

const (
	MaxDigits      = 20                          // max digits in a u64
	MaxFormattedLen = MaxDigits + (MaxDigits-1)/3 // 26: with commas
)

var (
	ErrBufferTooSmall = errors.New("BufferTooSmall")
	ErrInvalidInput   = errors.New("InvalidInput")
)

// FormatWithCommas formats a numeric byte string with commas every 3 digits
// from the right. Returns a fixed-size buffer by value and the length of the
// formatted result. Use buf[:n] to get the result slice.
// Zero heap allocations.
func FormatWithCommas(numStr []byte) (buf [MaxFormattedLen]byte, n int, err error) {
	numLen := len(numStr)
	numComma := (numLen - 1) / 3
	finalLen := numLen + numComma

	if finalLen > MaxFormattedLen {
		err = ErrBufferTooSmall
		return
	}

	strIdx := numLen
	destIdx := finalLen
	digitCount := 0

	for strIdx > 0 {
		if digitCount == 3 {
			destIdx--
			buf[destIdx] = ','
			digitCount = 0
		}

		strIdx--
		destIdx--

		c := numStr[strIdx]
		if c < '0' || c > '9' {
			err = ErrInvalidInput
			return
		}

		buf[destIdx] = c
		digitCount++
	}

	n = finalLen
	return
}
