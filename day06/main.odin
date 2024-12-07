package main

import "core:encoding/ansi"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"

Vec2 :: [2]int // x, y

Tile :: enum {
	Empty,
	Obstacle,
	Visited,
}

Grid :: struct {
	width:     int,
	height:    int,
	tiles:     [dynamic]Tile,
	guard_pos: Vec2,
	guard_dir: Vec2,
}

UP :: Vec2{0, -1}
DOWN :: Vec2{0, 1}
LEFT :: Vec2{-1, 0}
RIGHT :: Vec2{1, 0}

get_tile :: proc(grid: Grid, pos: Vec2) -> ^Tile {
	if pos.x < 0 || pos.y < 0 || pos.x >= grid.width || pos.y >= grid.height {
		return nil
	}
	return &grid.tiles[pos.y * grid.width + pos.x]
}

print_grid :: proc(grid: Grid, clear_screen: bool = true) {
	RST :: ansi.CSI + ansi.RESET + ansi.SGR
	TILE_EMPTY :: ansi.CSI + ansi.FG_WHITE + ansi.SGR + "." + RST
	TILE_OBSTACLE :: ansi.CSI + ansi.FG_GREEN + ansi.SGR + "#" + RST
	TILE_VISITED :: ansi.CSI + ansi.BG_BLUE + ansi.SGR + "." + RST

	if clear_screen {
		fmt.print(ansi.CSI + "2" + ansi.ED)
	}

	first := true
	for tile, i in grid.tiles {
		if first {
			first = false
		} else if i % grid.width == 0 {
			fmt.println()
		}
		if grid.guard_pos.x == i % grid.width && grid.guard_pos.y == i / grid.width {
			fmt.print(ansi.CSI + ansi.FG_RED)
			if tile == Tile.Visited {
				fmt.print(";" + ansi.BG_BLUE)
			}
			fmt.print(ansi.SGR)
			switch grid.guard_dir {
			case UP:
				fmt.print("^")
			case DOWN:
				fmt.print("v")
			case LEFT:
				fmt.print("<")
			case RIGHT:
				fmt.print(">")
			}
			fmt.print(RST)
			continue
		}
		switch tile {
		case Tile.Empty:
			fmt.print(TILE_EMPTY)
		case Tile.Obstacle:
			fmt.print(TILE_OBSTACLE)
		case Tile.Visited:
			fmt.print(TILE_VISITED)
		}
	}
	fmt.print(RST + "\n\n")
}

turn_90 :: proc(dir: Vec2) -> Vec2 {
	switch dir {
	case UP:
		return RIGHT
	case RIGHT:
		return DOWN
	case DOWN:
		return LEFT
	case LEFT:
		return UP
	}
	panic("invalid direction")
}

clone_grid :: proc(grid: Grid, allocator := context.allocator) -> Grid {
	new_grid := grid
	new_grid.tiles = make([dynamic]Tile, len(grid.tiles), allocator)
	copy(new_grid.tiles[:], grid.tiles[:])
	return new_grid
}

destroy_grid :: proc(grid: Grid) {
	delete(grid.tiles)
}

part1 :: proc(grid: Grid) {
	grid := clone_grid(grid)
	defer destroy_grid(grid)

	for {
		// print_grid(grid)

		forward_pos := grid.guard_pos + grid.guard_dir
		forward_tile := get_tile(grid, forward_pos)

		if forward_tile == nil {
			break
		}

		if forward_tile^ == Tile.Obstacle {
			grid.guard_dir = turn_90(grid.guard_dir)
			continue
		}

		forward_tile^ = Tile.Visited
		grid.guard_pos = forward_pos

		// time.sleep(time.Millisecond)
	}

	// print_grid(grid)

	visited := 0
	for tile in grid.tiles {
		if tile == Tile.Visited {
			visited += 1
		}
	}
	fmt.println("visited:", visited)
}

part2 :: proc(grid: Grid) {
	PosDir :: struct {
		pos: Vec2,
		dir: Vec2,
	}

	new_loop_obstacles := 0
	for tile, i in grid.tiles {
		defer free_all(context.temp_allocator)

		tile_pos := Vec2{i % grid.width, i / grid.width}
		if tile == Tile.Empty && grid.guard_pos != tile_pos {
			grid := clone_grid(grid, context.temp_allocator)
			visited_pos_dir := make(map[PosDir]bool, context.temp_allocator)

			visited_pos_dir[PosDir{grid.guard_pos, grid.guard_dir}] = true
			grid.tiles[i] = Tile.Obstacle

			for {
				// print_grid(grid)

				forward_pos := grid.guard_pos + grid.guard_dir
				forward_tile := get_tile(grid, forward_pos)

				if forward_tile == nil {
					break
				}

				if forward_tile^ == Tile.Obstacle {
					grid.guard_dir = turn_90(grid.guard_dir)
					continue
				}

				if visited_pos_dir[PosDir{forward_pos, grid.guard_dir}] {
					new_loop_obstacles += 1
					// print_grid(grid, false)
					break
				}

				forward_tile^ = Tile.Visited
				grid.guard_pos = forward_pos
				visited_pos_dir[PosDir{forward_pos, grid.guard_dir}] = true
			}

			// print_grid(grid)
		}
	}

	fmt.println("new_loop_obstacles:", new_loop_obstacles)
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

	grid: Grid
	defer destroy_grid(grid)

	text := string(data)
	for line in strings.split_lines_iterator(&text) {
		if grid.width == 0 {
			grid.width = len(line)
		} else {
			assert(grid.width == len(line))
		}

		y := grid.height
		grid.height += 1

		for c, x in line {
			tile := Tile.Empty

			switch c {
			case '#':
				tile = Tile.Obstacle
			case '^':
				grid.guard_pos = Vec2{x, y}
				grid.guard_dir = UP
				tile = Tile.Visited
			case 'v':
				grid.guard_pos = Vec2{x, y}
				grid.guard_dir = DOWN
				tile = Tile.Visited
			case '<':
				grid.guard_pos = Vec2{x, y}
				grid.guard_dir = LEFT
				tile = Tile.Visited
			case '>':
				grid.guard_pos = Vec2{x, y}
				grid.guard_dir = RIGHT
				tile = Tile.Visited
			}

			append(&grid.tiles, tile)
		}
	}

	part1(grid)
	part2(grid)
	// part2(grid)
}
