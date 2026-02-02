package commanum

import "errors"

const MaxLen = 64

var (
	ErrBufferTooSmall = errors.New("BufferTooSmall")
	ErrInvalidInput   = errors.New("InvalidInput")
)

// FormatWithCommas formats a numeric byte string with commas every 3 digits
// from the right. It writes into the provided buffer and returns a slice of it.
// Zero heap allocations in the hot path.
func FormatWithCommas(numStr []byte, buf []byte) ([]byte, error) {
	numLen := len(numStr)
	numComma := (numLen - 1) / 3
	finalLen := numLen + numComma

	if finalLen > len(buf) {
		return nil, ErrBufferTooSmall
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
			return nil, ErrInvalidInput
		}

		buf[destIdx] = c
		digitCount++
	}

	return buf[:finalLen], nil
}
