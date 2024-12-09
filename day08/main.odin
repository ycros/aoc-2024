package main

import "core:encoding/ansi"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

Tile :: struct {
	antenna:  Maybe(rune),
	antinode: bool,
}
Grid :: struct {
	tiles:         #soa[dynamic]Tile,
	width:         int,
	height:        int,
	antenna_types: map[rune]bool,
}
Vec2 :: [2]int // x, y

get_tile_index :: proc(grid: Grid, pos: Vec2) -> int {
	return pos.x + grid.width * pos.y
}

print_grid :: proc(grid: Grid) {
	for y := 0; y < grid.height; y += 1 {
		for x := 0; x < grid.width; x += 1 {
			tile := grid.tiles[get_tile_index(grid, Vec2{x, y})]
			if tile.antinode {
				fmt.print(ansi.CSI + ansi.BG_BRIGHT_YELLOW + ansi.SGR)
			}
			if tile.antenna != nil {
				fmt.print(tile.antenna)
			} else {
				fmt.print(".")
			}
			if tile.antinode {
				fmt.print(ansi.CSI + ansi.RESET + ansi.SGR)
			}
		}

		fmt.println()
	}
}

main :: proc() {
	data, ok := os.read_entire_file_from_filename("input.txt")
	assert(ok)
	defer delete(data)

	text := string(data)
	grid: Grid
	for line in strings.split_lines_iterator(&text) {
		if grid.width == 0 {
			grid.width = len(line)
		} else {
			assert(grid.width == len(line))
		}
		grid.height += 1

		line := line
		for c in line {
			if c == '.' {
				append(&grid.tiles, Tile{nil, false})
			} else {
				grid.antenna_types[c] = true
				append(&grid.tiles, Tile{c, false})
			}
		}
	}

	// print_grid(grid)

	for i := 0; i < len(grid.tiles); i += 1 {
		tile := grid.tiles[i]
		if tile.antenna == nil {
			continue
		}
		pos := Vec2{i % grid.width, i / grid.width}
		for j := i + 1; j < len(grid.tiles); j += 1 {
			other_tile := grid.tiles[j]
			if other_tile.antenna == tile.antenna {
				other_pos := Vec2{j % grid.width, j / grid.width}
				antinode_1_pos := pos + (pos - other_pos)
				antinode_2_pos := other_pos + (other_pos - pos)

				if antinode_1_pos.x >= 0 &&
				   antinode_1_pos.x < grid.width &&
				   antinode_1_pos.y >= 0 &&
				   antinode_1_pos.y < grid.height {
					grid.tiles[get_tile_index(grid, antinode_1_pos)].antinode = true
				}
				if antinode_2_pos.x >= 0 &&
				   antinode_2_pos.x < grid.width &&
				   antinode_2_pos.y >= 0 &&
				   antinode_2_pos.y < grid.height {
					grid.tiles[get_tile_index(grid, antinode_2_pos)].antinode = true
				}
			}
		}
	}

	print_grid(grid)

	antinodes := 0
	for i := 0; i < len(grid.tiles); i += 1 {
		if grid.tiles[i].antinode {
			antinodes += 1
		}
	}

	fmt.println("part1:", antinodes)
}
