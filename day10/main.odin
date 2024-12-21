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

part1 :: proc(grid: Grid) {
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

part1_first :: proc(grid: Grid) {
	zeroes := make([dynamic]int, 0, len(grid.data))
	for b, i in grid.data {
		if b == 0 {
			append(&zeroes, i)
		}
	}

	score := 0
	for zero in zeroes {
		head := index_to_vec(grid, zero)
		head_value := grid.data[zero]
		head_direction_vecs_index := 0

		trail := make([dynamic]Vec2, 0, len(grid.data))
		fully_seen := make(map[Vec2]struct {})
		append(&trail, head)

		for {
			fmt.println("pos", head, "trail", len(trail))
			// fmt.println(
			// 	"DEBUG: head:",
			// 	head,
			// 	"head_value:",
			// 	head_value,
			// 	"head_direction_vecs_index:",
			// 	head_direction_vecs_index,
			// )

			moved := false
			for i := head_direction_vecs_index; i < len(Direction_Vecs); i += 1 {
				dir := Direction(i)
				vec := Direction_Vecs[dir]
				next_pos := head + vec

				// fmt.println("DEBUG: checking", dir)

				if next_pos.x < 0 ||
				   next_pos.x >= grid.width ||
				   next_pos.y < 0 ||
				   next_pos.y >= grid.height {
					continue
				}

				next_value := grid.data[vec_to_index(grid, next_pos)]

				// fmt.println("DEBUG:", "next_pos: ", next_pos, "next_value: ", next_value)

				if next_value == 9 {
					// fmt.println("DEBUG: found a nine")
					score += 1
				} else if next_value == head_value + 1 && !(next_pos in fully_seen) {
					// fmt.println("DEBUG: moving to next value")
					head = next_pos
					head_value = next_value
					head_direction_vecs_index = 0
					append(&trail, head)
					moved = true
					break
				}
			}

			if !moved {
				// fmt.println("DEBUG: no more moves")
				old_head := pop(&trail)
				fully_seen[old_head] = {}

				if len(trail) == 0 {
					break
				}

				head = trail[len(trail) - 1]
				head_value = grid.data[vec_to_index(grid, head)]
				head_direction_vecs_index = 0
				for i := 0; i < len(Direction_Vecs); i += 1 {
					dir := Direction(i)
					vec := Direction_Vecs[dir]
					if head - vec == old_head {
						head_direction_vecs_index = i
						// fmt.println("DEBUG:", "old_head:", old_head, "head", head, "vec", vec)
						break
					}
				}
				continue
			}

			// fmt.println("DEBUG: keep moving")
		}
		break //temp
	}

	fmt.println("part1:", score)
}

main :: proc() {
	grid := populate_grid("input.txt")

	print_grid(grid)
	part1(grid)
}
