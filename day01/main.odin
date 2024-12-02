package main

import "core:bufio"
import "core:bytes"
import "core:fmt"
import "core:io"
import "core:os"
import "core:slice"
import "core:strconv"

main :: proc() {
	fd, err := os.open("input.txt")
	if err != nil {
		fmt.eprintln("Error opening file:", err)
		os.exit(1)
	}
	defer os.close(fd)

	stream := os.stream_from_handle(fd)

	scanner: bufio.Scanner
	bufio.scanner_init(&scanner, stream)
	scanner.split = bufio.scan_words

	left_numbers, right_numbers: [dynamic]int
	defer delete(left_numbers)
	defer delete(right_numbers)

	is_left := true
	for bufio.scanner_scan(&scanner) {
		word := bufio.scanner_text(&scanner)
		number, ok := strconv.parse_int(word)
		if !ok {
			fmt.eprintln("Error parsing number")
			os.exit(1)
		}
		if is_left {
			append(&left_numbers, number)
		} else {
			append(&right_numbers, number)
		}
		is_left = !is_left
	}
	assert(len(left_numbers) == len(right_numbers))

	part1(left_numbers[:], right_numbers[:])
}

part1 :: proc(left_numbers: []int, right_numbers: []int) {
	slice.sort(left_numbers)
	slice.sort(right_numbers)

	total_distance := 0
	for n in soa_zip(left = left_numbers, right = right_numbers) {
		distance := abs(n.left - n.right)
		// fmt.eprintln("Left:", n.left, "Right:", n.right, "Dist:", distance)
		total_distance += distance
	}

	fmt.println("Part 1, total distance:", total_distance)
}
