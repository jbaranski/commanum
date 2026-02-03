package commanum

import "errors"

const MaxDigits = 20 // max digits in a u64

var (
	ErrBufferTooSmall = errors.New("BufferTooSmall")
	ErrInvalidInput   = errors.New("InvalidInput")
)

// FormatWithCommas formats a numeric byte string with commas every 3 digits
// from the right. Returns a []byte sized to exactly the formatted length.
func FormatWithCommas(numStr []byte) ([]byte, error) {
	numLen := len(numStr)
	finalLen := numLen + (numLen-1)/3

	buf := make([]byte, finalLen)

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

	return buf, nil
}
