package main

import "core:bufio"
import "core:bytes"
import "core:fmt"
import "core:io"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:text/regex"

MUL_REGEX :: `mul\((\d+),(\d+)\)`
CONDITIONS_REGEX :: MUL_REGEX + `|do\(\)|don't\(\)`

eval :: proc(memory: string, handle_conditions: bool = false) -> int {
	defer free_all(context.temp_allocator)

	re_string := CONDITIONS_REGEX if handle_conditions else MUL_REGEX
	mul_regex, err := regex.create(re_string, {.Global}, context.temp_allocator)
	assert(err == nil, fmt.tprint("error compiling regex:", err))
	capture := regex.preallocate_capture(context.temp_allocator)

	start_index := 0
	sum := 0
	mul_enabled := true
	for start_index < len(memory) {
		if num_groups, success := regex.match_with_preallocated_capture(
			mul_regex,
			memory[start_index:],
			&capture,
		); success {
			if num_groups == 1 {
				if capture.groups[0] == "do()" {
					mul_enabled = true
				} else if capture.groups[0] == "don't()" {
					mul_enabled = false
				} else {
					panic("invalid instruction or group match!")
				}
			} else {
				assert(num_groups == 3, fmt.tprint("expected num groups 3, got:", num_groups))
				if mul_enabled {
					x := strconv.atoi(capture.groups[1])
					y := strconv.atoi(capture.groups[2])
					sum += x * y
				}
			}
			start_index += capture.pos[0][1]
		} else {
			break
		}
	}
	return sum
}

part1 :: proc(memory: string) {
	fmt.println("part1:", eval(memory))
}

part2 :: proc(memory: string) {
	fmt.println("part2:", eval(memory, handle_conditions = true))
}

main :: proc() {
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

	data, ok := os.read_entire_file_from_filename("input.txt")
	assert(ok)
	defer delete(data)

	text := string(data)

	part1(text)
	part2(text)
}
