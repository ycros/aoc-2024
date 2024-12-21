package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import sv "core:strconv"
import "core:strings"
import "core:time"

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

main :: proc() {
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

	fmt.println(len(stones))
}
