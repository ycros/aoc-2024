package main

import "core:bufio"
import "core:bytes"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

main :: proc() {
	using bufio

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	fd, err := os.open("input.txt")
	if err != nil {
		fmt.eprintln("Error opening file:", err)
		os.exit(1)
	}

	file_stream := os.stream_from_handle(fd)

	line_scanner: Scanner
	scanner_init(&line_scanner, file_stream)
	defer scanner_destroy(&line_scanner)

	reports: [dynamic][]int
	defer {
		for r in reports {
			delete(r)
		}
		delete(reports)
	}

	for scanner_scan(&line_scanner) {
		line := scanner_text(&line_scanner)
		splits := strings.split(line, " ")
		defer delete(splits)
		assert(len(splits) > 0)

		report := make([]int, len(splits))
		for s, i in splits {
			report[i] = strconv.atoi(s)
		}
		append(&reports, report)
	}
	assert(len(reports) > 0)

	part1(reports)
	part2(reports)
}

LevelDirection :: enum {
	Undecided,
	Increasing,
	Decreasing,
}

part1 :: proc(reports: [dynamic][]int) {
	safe_count := 0
	for report in reports {
		first := true
		safe := true
		previous_level := 0
		direction := LevelDirection.Undecided
		loop: for level in report {
			if first {
				first = false
				previous_level = level
				continue
			}
			delta := level - previous_level

			if delta == 0 {
				safe = false
				// fmt.println("UNSAFE:", direction, previous_level, level, delta)
				break
			}

			if direction == .Undecided {
				if delta > 0 {
					direction = .Increasing
				} else if delta < 0 {
					direction = .Decreasing
				} else {
					panic("Shouldn't have gotten here.")
				}
			}

			switch {
			case direction == .Increasing && (delta < 1 || delta > 3):
				fallthrough
			case direction == .Decreasing && (delta > -1 || delta < -3):
				// fmt.println("UNSAFE:", direction, previous_level, level, delta)
				safe = false
				break loop
			}

			previous_level = level
		}

		// fmt.println(report, safe)

		if safe do safe_count += 1
	}

	fmt.println("part1, safe count:", safe_count)
}

part2 :: proc(reports: [dynamic][]int) {
	test_report :: proc(report: []int, skip: int) -> (safe: bool, bad_index: int) {
		// fmt.println(report)
		first := true
		previous_level := 0
		direction := LevelDirection.Undecided
		loop: for level, i in report {
			if i == skip {
				continue
			}
			if first {
				first = false
				previous_level = level
				continue
			}
			delta := level - previous_level

			if delta == 0 {
				// fmt.println("UNSAFE:", direction, previous_level, level, delta)
				return false, i
			}

			if direction == .Undecided {
				if delta > 0 {
					direction = .Increasing
				} else if delta < 0 {
					direction = .Decreasing
				} else {
					panic("Shouldn't have gotten here.")
				}
			}

			switch {
			case direction == .Increasing && (delta < 1 || delta > 3):
				fallthrough
			case direction == .Decreasing && (delta > -1 || delta < -3):
				// fmt.println("UNSAFE:", direction, previous_level, level, delta)
				return false, i
			}

			previous_level = level
		}

		return true, -1
	}

	total_safe_reports := 0
	for report in reports {
		safe: bool
		unsafe_index: int
		safe, unsafe_index = test_report(report, -1)

		for !safe && unsafe_index >= 0 {
			safe, _ = test_report(report, unsafe_index)
			unsafe_index -= 1
		}

		// fmt.println("SAFE:", safe)
		// fmt.println()

		if safe do total_safe_reports += 1
	}

	fmt.println("part2, safe count:", total_safe_reports)
}
