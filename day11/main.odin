package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import sv "core:strconv"
import "core:strings"
import "core:time"

part2 :: proc() {

	Stone :: struct {
		next:  ^Stone,
		value: string,
	}

	insert_after :: proc(stone: ^Stone, new_stone: ^Stone) {
		new_stone.next = stone.next
		stone.next = new_stone
	}

	int_to_str :: proc(builder: ^strings.Builder, value: int) -> string {
		strings.write_int(builder, value)
		result := strings.clone(strings.to_string(builder^))
		strings.builder_reset(builder)
		return result
	}

	blink :: proc(head: ^Stone, builder: ^strings.Builder) {
		for s := head; s != nil; s = s.next {
			if s.value == "0" {
				delete(s.value)
				s.value = strings.clone("1")
			} else if len(s.value) % 2 == 0 {
				first_half := s.value[:len(s.value) / 2]
				second_half := s.value[len(s.value) / 2:]

				first_clone := int_to_str(builder, sv.atoi(first_half))
				second_clone := int_to_str(builder, sv.atoi(second_half))

				delete(s.value)
				s.value = first_clone

				next_s := new(Stone)
				next_s.value = second_clone
				insert_after(s, next_s)
				s = next_s
			} else {
				strings.write_int(builder, sv.atoi(s.value) * 2024)
				delete(s.value)
				s.value = strings.clone(strings.to_string(builder^))
				strings.builder_reset(builder)
			}
		}
	}

	print_stones :: proc(head: ^Stone) {
		for s := head; s != nil; s = s.next {
			fmt.print(s.value, "")
		}
		fmt.println()
	}

	data, ok := os.read_entire_file_from_filename("input.txt")
	defer delete(data)
	assert(ok)

	head: ^Stone
	tail: ^Stone

	data_string := string(data)
	first := true
	for word in strings.split_iterator(&data_string, " ") {
		node := new(Stone)
		node.value = strings.clone(word)
		if head == nil {
			head = node
			tail = node
		} else {
			tail.next = node
			tail = node
		}
	}

	builder: strings.Builder
	defer strings.builder_destroy(&builder)

	for i := 0; i < 75; i += 1 {
		// print_stones(head)
		fmt.println("round", i)
		blink(head, &builder)
	}
	// print_stones(head)

	stone_count := 0
	for s := head; s != nil; {
		stone_count += 1
		delete(s.value)
		old_s := s
		s = s.next
		free(old_s)
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
	// when ODIN_DEBUG {
	// 	track: mem.Tracking_Allocator
	// 	mem.tracking_allocator_init(&track, context.allocator)
	// 	context.allocator = mem.tracking_allocator(&track)

	// 	defer {
	// 		if len(track.allocation_map) > 0 {
	// 			fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
	// 			for _, entry in track.allocation_map {
	// 				fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
	// 			}
	// 		}
	// 		if len(track.bad_free_array) > 0 {
	// 			fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
	// 			for entry in track.bad_free_array {
	// 				fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
	// 			}
	// 		}
	// 		mem.tracking_allocator_destroy(&track)
	// 	}
	// }

	// part1()
	part2()
}
