package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import sv "core:strconv"
import "core:strings"
import "core:time"

part2 :: proc() {

	int_to_str :: proc(builder: ^strings.Builder, value: int) -> string {
		strings.write_int(builder, value)
		result := strings.clone(strings.to_string(builder^))
		strings.builder_reset(builder)
		return result
	}

	blink :: proc(stones: map[string]int, builder: ^strings.Builder) -> map[string]int {
		new_stones := make(map[string]int)

		for s, count in stones {
			if s == "0" {
				new_stones["1"] += count
			} else if len(s) % 2 == 0 {
				first_half := s[:len(s) / 2]
				second_half := s[len(s) / 2:]

				first_clone := int_to_str(builder, sv.atoi(first_half))
				second_clone := int_to_str(builder, sv.atoi(second_half))

				new_stones[first_clone] += count
				new_stones[second_clone] += count
			} else {
				m := int_to_str(builder, sv.atoi(s) * 2024)
				new_stones[m] += count
			}
		}

		return new_stones
	}

	data, ok := os.read_entire_file_from_filename("input.txt")
	defer delete(data)
	assert(ok)

	data_string := string(data)
	stones := make(map[string]int)
	for word in strings.split_iterator(&data_string, " ") {
		stones[word] += 1
	}

	builder: strings.Builder
	defer strings.builder_destroy(&builder)

	for i := 0; i < 75; i += 1 {
		stones = blink(stones, &builder)
	}

	stone_count := 0
	for s, count in stones {
		stone_count += count
	}

	fmt.println("part2:", stone_count)
}

part1 :: proc() {
	Stones :: [dynamic]string

	blink :: proc(stones: ^Stones) {
		to_insert := make(map[int]string)

		for i := 0; i < len(stones); i += 1 {
			stone := stones[i]
			if stone == "0" {
				delete(stones[i])
				stones[i] = strings.clone("1")
			} else if len(stone) % 2 == 0 {
				first_buf := make([]byte, len(stone) / 2)
				second_buf := make([]byte, len(stone) / 2)
				first := sv.itoa(first_buf, sv.atoi(stone[:len(stone) / 2]))
				second := sv.itoa(second_buf, sv.atoi(stone[len(stone) / 2:]))
				delete(stones[i])
				stones[i] = first
				inject_at(stones, i + 1, second)
				i += 1
			} else {
				new_stone_buf := make([]byte, len(stone) * 10)
				new_stone := sv.itoa(new_stone_buf, sv.atoi(stone) * 2024)
				delete(stones[i])
				stones[i] = new_stone
			}
		}
	}

	data, ok := os.read_entire_file_from_filename("input.txt")
	assert(ok)

	stones := make(Stones)

	data_string := string(data)
	for word in strings.split_iterator(&data_string, " ") {
		append(&stones, strings.clone(word))
	}

	for i := 0; i < 25; i += 1 {
		// fmt.println(stones)
		blink(&stones)
	}

	fmt.println("part1:", len(stones))
}

main :: proc() {
	// part1()
	part2()
}
