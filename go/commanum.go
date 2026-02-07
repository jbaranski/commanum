package commanum

const MaxLen = 64
const WordsMaxLen = 1024

// FormatWithCommas formats a numeric string with commas every 3 digits from the right.
func FormatWithCommas(numStr string) (string, error) {
	numLen := len(numStr)
	numComma := (numLen - 1) / 3
	finalLen := numLen + numComma

	if finalLen > MaxLen {
		return "", &Error{"BufferTooSmall"}
	}

	// Validate all characters are digits
	for i := 0; i < numLen; i++ {
		if numStr[i] < '0' || numStr[i] > '9' {
			return "", &Error{"InvalidInput"}
		}
	}

	// Build result from right to left
	result := make([]byte, finalLen)
	strIdx := numLen
	destIdx := finalLen
	digitCount := 0

	for strIdx > 0 {
		if digitCount == 3 {
			destIdx--
			result[destIdx] = ','
			digitCount = 0
		}

		destIdx--
		strIdx--
		result[destIdx] = numStr[strIdx]
		digitCount++
	}

	return string(result), nil
}

var ones = []string{
	"", "one", "two", "three", "four", "five",
	"six", "seven", "eight", "nine", "ten",
	"eleven", "twelve", "thirteen", "fourteen", "fifteen",
	"sixteen", "seventeen", "eighteen", "nineteen",
}

// [0] unused, [1] unused (10-19 are handled by the ones table above)
var tens = []string{
	"", "", "twenty", "thirty", "forty", "fifty",
	"sixty", "seventy", "eighty", "ninety",
}

var scaleNames = []string{
	"", "thousand", "million", "billion", "trillion",
	"quadrillion", "quintillion", "sextillion",
}

// groupToWords converts a group value (0-999) to words.
func groupToWords(n int) string {
	if n == 0 {
		return ""
	}

	var parts []string

	if n >= 100 {
		parts = append(parts, ones[n/100]+" hundred")
		n = n % 100
		if n > 0 {
			parts = append(parts, "and")
		}
	}

	if n >= 20 {
		word := tens[n/10]
		remainder := n % 10
		if remainder > 0 {
			word += "-" + ones[remainder]
		}
		parts = append(parts, word)
	} else if n > 0 {
		parts = append(parts, ones[n])
	}

	result := ""
	for i, part := range parts {
		if i > 0 {
			result += " "
		}
		result += part
	}
	return result
}

// NumberToWords converts a numeric string to English words.
// Assumes input is already validated (digits only, no leading zeros except "0").
func NumberToWords(numStr string) string {
	if numStr == "0" {
		return "Zero"
	}

	// Parse groups of 3 from right to left
	var groupValues []int
	i := len(numStr)
	for i > 0 {
		groupStart := i - 3
		if groupStart < 0 {
			groupStart = 0
		}
		groupStr := numStr[groupStart:i]
		groupVal := 0
		for _, c := range groupStr {
			groupVal = groupVal*10 + int(c-'0')
		}
		groupValues = append(groupValues, groupVal)
		i = groupStart
	}

	// Build words from highest group to lowest
	var parts []string
	numGroups := len(groupValues)
	for gi := numGroups - 1; gi >= 0; gi-- {
		val := groupValues[gi]
		if val > 0 {
			// Insert "and" before the last nonzero group if it's < 100
			// and there are already higher-order parts written
			if gi == 0 && val < 100 && len(parts) > 0 {
				parts = append(parts, "and "+groupToWords(val))
			} else {
				words := groupToWords(val)
				if scaleNames[gi] != "" {
					words += " " + scaleNames[gi]
				}
				parts = append(parts, words)
			}
		}
	}

	result := ""
	for i, part := range parts {
		if i > 0 {
			result += " "
		}
		result += part
	}

	// Capitalize first letter
	if len(result) > 0 && result[0] >= 'a' && result[0] <= 'z' {
		result = string(result[0]-32) + result[1:]
	}

	return result
}

// Error represents a commanum error.
type Error struct {
	Message string
}

func (e *Error) Error() string {
	return e.Message
}
