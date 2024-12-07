package main

import ba "core:container/bit_array"
import "core:container/topological_sort"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import scv "core:strconv"
import "core:strings"
import re "core:text/regex"

OrderRule :: struct {
	before: int,
	after:  int,
}
State :: struct {
	order_rules:     [dynamic]OrderRule,
	updates:         [dynamic][dynamic]int,
	invalid_updates: [dynamic][dynamic]int,
	max_page:        int,
}

parse :: proc(text: string) -> (state: State) {
	rule_re, err := re.create(`(\d+)\|(\d+)`)
	capture := re.preallocate_capture()
	assert(err == nil)

	text := text
	in_rules := true

	for line in strings.split_lines_iterator(&text) {
		if line == "" {
			in_rules = false
			continue
		}

		if in_rules {
			num_groups, ok := re.match(rule_re, line, &capture)
			assert(ok)
			assert(num_groups == 3)
			append(
				&state.order_rules,
				OrderRule {
					before = scv.atoi(capture.groups[1]),
					after = scv.atoi(capture.groups[2]),
				},
			)
		} else {
			line := line
			update := make([dynamic]int)
			for page in strings.split_iterator(&line, ",") {
				page_num := scv.atoi(page)
				state.max_page = max(state.max_page, page_num)
				append(&update, page_num)
			}
			append(&state.updates, update)
		}
	}

	return state
}

reorder_and_return_middle :: proc(update: [dynamic]int, rules: [dynamic]OrderRule) -> int {
	using topological_sort

	sorter: Sorter(int)
	defer destroy(&sorter)
	init(&sorter)

	for page in update {
		if !add_key(&sorter, page) {
			fmt.println("duplicate page:", page)
		}
	}

	for rule in rules {
		if !add_dependency(&sorter, rule.after, rule.before) {
			fmt.println("couldn't add dependency:", rule.before, rule.after)
		}
	}

	sorted, cycled := sort(&sorter)

	assert(len(cycled) == 0, "cycle detected")

	return sorted[len(sorted) / 2]
}

part1 :: proc(state: ^State) {
	valid_middles := 0
	for update in state.updates {
		pages := make(map[int]bool)
		defer delete(pages)

		for page in update {
			pages[page] = true
		}

		update_valid := true
		for rule in state.order_rules {
			if !(rule.after in pages) || !(rule.before in pages) {
				continue
			}

			for page in update {
				if page == rule.after {
					update_valid = false
					break
				} else if page == rule.before {
					break
				}
			}

			if !update_valid {
				break
			}
		}

		if update_valid {
			valid_middles += update[len(update) / 2]
		} else {
			append(&state.invalid_updates, update)
		}
	}

	fmt.println("part1:", valid_middles)
}

part2 :: proc(state: State) {
	reordered_middles := 0
	for update in state.invalid_updates {
		pages := make(map[int]bool)
		defer delete(pages)

		for page in update {
			pages[page] = true
		}

		applicable_rules: [dynamic]OrderRule
		defer delete(applicable_rules)

		for rule in state.order_rules {
			if !(rule.after in pages) || !(rule.before in pages) {
				continue
			}
			append(&applicable_rules, rule)
		}

		reordered_middles += reorder_and_return_middle(update, applicable_rules)
	}

	fmt.println("part2:", reordered_middles)
}

main :: proc() {
	data, ok := os.read_entire_file_from_filename("input.txt")
	assert(ok)
	defer delete(data)

	text := string(data)
	lines := strings.split_lines(text)

	state := parse(text)

	part1(&state)
	part2(state)
}
