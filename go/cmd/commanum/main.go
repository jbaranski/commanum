package main

import (
	"fmt"
	"os"

	"commanum"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Error: Missing argument.")
		os.Exit(1)
	}
	if len(os.Args) > 2 {
		fmt.Fprintln(os.Stderr, "Error: Too many arguments.")
		os.Exit(1)
	}

	input := []byte(os.Args[1])

	buf, n, err := commanum.FormatWithCommas(input)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error: Please provide only digits")
		os.Exit(1)
	}

	os.Stdout.Write(buf[:n])
	os.Stdout.Write([]byte{'\n'})
}
