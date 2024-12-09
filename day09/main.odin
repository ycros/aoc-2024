package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"

FREE_SPACE :: -1

ctoi :: proc(c: rune) -> int {
	return int(c - '0')
}

checksum :: proc(disk: []int) -> int {
	result := 0
	for n, i in disk {
		if n == FREE_SPACE {
			continue
		}
		result += n * i
	}
	return result
}

print_disk :: proc(disk: []int) {
	for i in disk {
		if i == FREE_SPACE {
			fmt.print(".")
		} else {
			if i > 9 {
				panic("print_disk only supports single digit numbers")
			}
			fmt.printf("%d", i)
		}
	}
	fmt.println()
}

part1 :: proc(disk: []int) {
	disk := disk

	fwd_i := 0
	for i := len(disk) - 1; i >= 0 && i > fwd_i; i -= 1 {
		if disk[i] == FREE_SPACE {
			continue
		}
		for i > fwd_i {
			if disk[fwd_i] == FREE_SPACE {
				disk[fwd_i] = disk[i]
				disk[i] = FREE_SPACE
				break
			}
			fwd_i += 1
		}
	}

	fmt.println("part1:", checksum(disk))
}

part2 :: proc(disk: []int) {
	find_next_free_space :: proc(disk: []int, start: int) -> (space_start, space_len: int) {
		is_counting_space := false
		for i := start; i < len(disk); i += 1 {
			if disk[i] != FREE_SPACE {
				if is_counting_space {
					break
				}
				continue
			}
			if !is_counting_space {
				is_counting_space = true
				space_start = i
			}
			space_len += 1
		}
		return
	}

	reverse_find_next_file :: proc(
		disk: []int,
		start: int,
		id_limit: int = -1,
	) -> (
		file_start, file_len, file_id: int,
	) {
		is_counting_file := false
		file_id = -1
		i := 0
		for i = start; i >= 0; i -= 1 {
			if is_counting_file && disk[i] != file_id {
				break
			}
			if disk[i] == FREE_SPACE {
				continue
			}
			if id_limit != -1 && disk[i] > id_limit {
				continue
			}
			if !is_counting_file {
				is_counting_file = true
				file_id = disk[i]
			}
			file_len += 1
		}
		file_start = i + 1
		return
	}

	disk := disk

	space_search_pos := 0
	file_start, file_len, file_id := reverse_find_next_file(disk, len(disk) - 1)
	for {
		space_start, space_len := find_next_free_space(disk, space_search_pos)
		space_not_found := space_len == 0 || space_start > file_start
		file_fits := file_len <= space_len
		if space_not_found || file_fits {
			if !space_not_found {
				copy(disk[space_start:], disk[file_start:file_start + file_len])
				slice.fill(disk[file_start:file_start + file_len], FREE_SPACE)
			}
			file_start, file_len, file_id = reverse_find_next_file(disk, file_start - 1, file_id)
			space_search_pos = 0
			if file_id == -1 {
				break
			}
			continue
		}

		space_search_pos = space_start + space_len
	}

	fmt.println("part2:", checksum(disk))
}

make_disk :: proc(text: string) -> []int {
	disk: [dynamic]int
	id_counter := 0

	for c, i in text {
		if i % 2 == 0 { 	// file
			for j := 0; j < ctoi(c); j += 1 {
				append(&disk, id_counter)
			}
			id_counter += 1
		} else { 	// spaec
			for j := 0; j < ctoi(c); j += 1 {
				append(&disk, FREE_SPACE)
			}
		}
	}
	return disk[:]
}

main :: proc() {
	data, ok := os.read_entire_file_from_filename("input.txt")
	assert(ok)
	defer delete(data)

	text := string(data)
	part1(make_disk(text))
	part2(make_disk(text))
}
