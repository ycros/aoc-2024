package main

import sa "core:container/small_array"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"

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

get_tile :: proc(grid: Grid, pos: Vec2) -> ^Tile {
	return &grid.tiles[pos.y * grid.width + pos.x]
}

search_one :: proc(grid: Grid, start: Vec2, direction: Vec2) -> bool {
	cur := start
	word := "XMAS"
	word_index := 0
	found_positions: sa.Small_Array(4, Vec2)

	for word_index < len(word) {
		if cur.x < 0 || cur.y < 0 || cur.x >= grid.width || cur.y >= grid.height {
			return false
		}
		if get_tile(grid, cur).char != word[word_index] {
			return false
		}
		sa.append(&found_positions, cur)
		word_index += 1
		cur += direction
	}

	for fp in sa.slice(&found_positions) {
		get_tile(grid, fp).found = true
	}

	return true
}

search_x :: proc(grid: Grid, start: Vec2) -> bool {
	TOP_LEFT :: Vec2{-1, -1}
	TOP_RIGHT :: Vec2{1, -1}
	BTM_LEFT :: Vec2{-1, 1}
	BTM_RIGHT :: Vec2{1, 1}

	ms_check :: proc(a: Tile, b: Tile) -> bool {
		return a.char == 'M' && b.char == 'S' || a.char == 'S' && b.char == 'M'
	}

	if start.x < 1 || start.x >= grid.width - 1 || start.y < 1 || start.y >= grid.height - 1 {
		return false
	}
	middle := get_tile(grid, start)
	if middle.char != 'A' {
		return false
	}

	top_left := get_tile(grid, start + TOP_LEFT)
	top_right := get_tile(grid, start + TOP_RIGHT)
	btm_left := get_tile(grid, start + BTM_LEFT)
	btm_right := get_tile(grid, start + BTM_RIGHT)

	if !ms_check(top_left^, btm_right^) || !ms_check(top_right^, btm_left^) {
		return false
	}

	middle.found = true
	top_left.found = true
	top_right.found = true
	btm_left.found = true
	btm_right.found = true

	return true
}

parse_to_grid :: proc(text: string) -> Grid {
	using strings
	lines := split_lines(text)
	grid := Grid {
		width  = len(lines[0]),
		height = len(lines),
		tiles  = make([dynamic]Tile),
	}
	for y := 0; y < len(lines); y += 1 {
		for x := 0; x < len(lines[0]); x += 1 {
			assert(grid.width == len(lines[0]))
			append(&grid.tiles, Tile{char = lines[y][x], found = false})
		}
	}
	return grid
}

print_grid :: proc(grid: Grid) {
	first := true
	for tile, i in grid.tiles {
		if first {
			first = false
		} else if i % grid.width == 0 {
			fmt.println()
		}
		fmt.printf("%c", tile.char if tile.found else '.')
	}
	fmt.print("\n\n")
}

part1 :: proc(text: string) {
	context.allocator = context.temp_allocator
	defer free_all(context.temp_allocator)
	grid := parse_to_grid(text)

	found := 0
	for x := 0; x < grid.width; x += 1 {
		for y := 0; y < grid.height; y += 1 {
			for j := -1; j < 2; j += 1 {
				for k := -1; k < 2; k += 1 {
					found += int(search_one(grid, Vec2{x, y}, Vec2{j, k}))
				}
			}
		}
	}

	fmt.println("part1:", found)
	print_grid(grid)
}

part2 :: proc(text: string) {
	context.allocator = context.temp_allocator
	defer free_all(context.temp_allocator)
	grid := parse_to_grid(text)

	found := 0
	for x := 0; x < grid.width; x += 1 {
		for y := 0; y < grid.height; y += 1 {
			found += int(search_x(grid, Vec2{x, y}))
		}
	}

	fmt.println("part2:", found)
	print_grid(grid)
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
