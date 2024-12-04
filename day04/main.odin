package main

import sa "core:container/small_array"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"

WORD :: "XMAS"

Vec2 :: [2]int // x, y
Tile :: struct {
	char:  byte,
	found: bool,
}
Grid :: struct {
	width:  int,
	height: int,
	tiles:  [dynamic]Tile,
}

search :: proc(grid: Grid, start: Vec2, direction: Vec2) -> bool {
	cur := start
	word := WORD
	word_index := 0
	found_positions: sa.Small_Array(4, Vec2)

	for word_index < len(word) {
		if cur.x < 0 || cur.y < 0 || cur.x >= grid.width || cur.y >= grid.height {
			return false
		}
		if grid.tiles[cur.y * grid.width + cur.x].char != word[word_index] {
			return false
		}
		sa.append(&found_positions, cur)
		word_index += 1
		cur += direction
	}

	for fp in sa.slice(&found_positions) {
		grid.tiles[fp.y * grid.width + fp.x].found = true
	}

	return true
}

part1 :: proc(text: string) {
	using strings
	defer free_all(context.temp_allocator)

	lines := split_lines(text, context.temp_allocator)
	grid := Grid {
		width  = len(lines[0]),
		height = len(lines),
	}
	defer delete(grid.tiles)
	for y := 0; y < len(lines); y += 1 {
		for x := 0; x < len(lines[0]); x += 1 {
			assert(grid.width == len(lines[0]))
			append(&grid.tiles, Tile{char = lines[y][x], found = false})
		}
	}

	found := 0
	for x := 0; x < grid.width; x += 1 {
		for y := 0; y < grid.height; y += 1 {
			for j := -1; j < 2; j += 1 {
				for k := -1; k < 2; k += 1 {
					found += int(search(grid, Vec2{x, y}, Vec2{j, k}))
				}
			}
		}
	}

	fmt.println("found:", found)
	for tile, i in grid.tiles {
		if i % grid.width == 0 {
			fmt.println()
		}
		fmt.printf("%c", tile.char if tile.found else '.')
	}
	fmt.println()
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
}
