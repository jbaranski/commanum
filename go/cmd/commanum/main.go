package main

import (
	"commanum"
	"fmt"
	"os"
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

	input := os.Args[1]

	formatted, err := commanum.FormatWithCommas(input)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error: Please provide only digits")
		os.Exit(1)
	}

	if len(input) > 1 && input[0] == '0' {
		fmt.Fprintln(os.Stderr, "Error: Leading zeros are not allowed")
		os.Exit(1)
	}

	words := commanum.NumberToWords(input)

	fmt.Println()
	fmt.Println("  Digits :", input)
	fmt.Println("  Commas :", formatted)
	fmt.Println("   Words :", words)
	fmt.Println()
}
