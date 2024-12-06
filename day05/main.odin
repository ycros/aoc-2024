package main

import "core:fmt"
import "core:mem"
import "core:os"
import scv "core:strconv"
import "core:strings"
import re "core:text/regex"

OrderRule :: struct {
	a: int,
	b: int,
}
Rule :: union {
	OrderRule,
}

main :: proc() {
	data, ok := os.read_entire_file_from_filename("sample.txt")
	assert(ok)
	defer delete(data)

	text := string(data)
	lines := strings.split_lines(text)

	rule_re, err := re.create(`(\d+)\|(\d+)`)
	capture := re.preallocate_capture()
	assert(err == nil)

	rules: [dynamic]Rule

	in_rules := true

	for line in lines {
		if line == "" {
			in_rules = false
			continue
		}

		if in_rules {
			num_groups, ok := re.match(rule_re, line, &capture)
			assert(ok)
			assert(num_groups == 3)
			append(
				&rules,
				OrderRule{a = scv.atoi(capture.groups[1]), b = scv.atoi(capture.groups[2])},
			)
		} else {
			strings.split_iterator()
		}
	}

	fmt.println(rules)
}
