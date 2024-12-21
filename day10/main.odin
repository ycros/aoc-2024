package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"

Vec2 :: [2]int
Grid :: struct {
	data:   []i8,
	height: int,
	width:  int,
}

Direction :: enum {
	Up,
	Down,
	Left,
	Right,
}
Direction_Vecs := [Direction]Vec2 {
	.Up    = {0, -1},
	.Down  = {0, 1},
	.Left  = {-1, 0},
	.Right = {1, 0},
}

btoi :: proc(c: byte) -> i8 {
	return i8(c - '0')
}

vec_to_index :: proc(grid: Grid, vec: Vec2) -> int {
	return vec.y * grid.width + vec.x
}

index_to_vec :: proc(grid: Grid, i: int) -> Vec2 {
	return Vec2{i % grid.width, i / grid.width}
}

print_grid :: proc(grid: Grid) {
	for y := 0; y < grid.height; y += 1 {
		for x := 0; x < grid.width; x += 1 {
			b := grid.data[y * grid.width + x]
			if b == -1 {
				fmt.print(".")
			} else {
				fmt.printf("%d", grid.data[y * grid.width + x])
			}
		}
		fmt.println()
	}
}

populate_grid :: proc(file: string) -> Grid {
	data, ok := os.read_entire_file_from_filename(file)
	assert(ok)

	grid := Grid {
		height = 1,
	}
	grid_data := make([dynamic]i8, 0, len(data))

	i := 0
	in_new_line := false
	for b in data {
		if b == '\n' || b == '\r' {
			if !in_new_line {
				in_new_line = true
				grid.height += 1
				width := i / (grid.height - 1)
				if grid.width == 0 {
					grid.width = width
				} else {
					assert(grid.width == width)
				}
			}
			continue
		}
		in_new_line = false
		if b == '.' {
			append(&grid_data, -1)
		} else {
			append(&grid_data, btoi(b))
		}
		i += 1
	}
	grid.data = grid_data[:]
	return grid
}

part1 :: proc(grid: Grid) {
	walk :: proc(grid: Grid, start: Vec2, seen: ^map[Vec2]struct {}, score: ^int) {
		seen[start] = {}
		start_value := grid.data[vec_to_index(grid, start)]
		for vec, direction in Direction_Vecs {
			next_pos := start + vec
			if next_pos.x < 0 ||
			   next_pos.x >= grid.width ||
			   next_pos.y < 0 ||
			   next_pos.y >= grid.height {
				continue
			}
			if next_pos in seen {
				continue
			}
			next_value := grid.data[vec_to_index(grid, next_pos)]
			if next_value == start_value + 1 {
				if next_value == 9 {
					score^ += 1
					seen[next_pos] = {}
					continue
				}
				walk(grid, next_pos, seen, score)
			}
		}
	}

	zeroes := make([dynamic]Vec2, 0, len(grid.data))
	for b, i in grid.data {
		if b == 0 {
			append(&zeroes, index_to_vec(grid, i))
		}
	}

	score := 0
	for zero in zeroes {
		seen := make(map[Vec2]struct {})
		walk(grid, zero, &seen, &score)
	}

	fmt.println("part1:", score)
}

main :: proc() {
	grid := populate_grid("input.txt")

	print_grid(grid)
	part1(grid)
}
