package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"

Operator :: enum {
	Add,
	Mul,
}

main :: proc() {
	data, ok := os.read_entire_file_from_filename("input.txt")
	assert(ok)
	defer delete(data)

	totals := 0
	text := string(data)
	for line in strings.split_lines_iterator(&text) {
		line := line

		expected_result := 0
		operands: [dynamic]int
		defer delete(operands)
		first := true
		for bit in strings.split_iterator(&line, " ") {
			if first {
				first = false
				expected_result = strconv.atoi(bit[:len(bit) - 1])
				continue
			}
			append(&operands, strconv.atoi(bit))
		}

		fmt.print(operands)
		fmt.println(" =", expected_result)

		operators := make([]Operator, len(operands) - 1)
		defer delete(operators)
		for i := 0; i < len(operators); i += 1 {
			operators[i] = Operator.Add
		}

		found := false
		outer: for {
			acc := operands[0]
			for i := 1; i < len(operands); i += 1 {
				switch operators[i - 1] {
				case Operator.Add:
					acc += operands[i]
				case Operator.Mul:
					acc *= operands[i]
				}
			}
			if acc == expected_result {
				found = true
				break
			}

			next_operator := Operator.Mul
			for i := 0; i < len(operators); i += 1 {
				if operators[i] == Operator.Mul {
					operators[i] = Operator.Add
					if i == len(operators) - 1 {
						break outer
					}
					continue
				}
				operators[i] += Operator(1)
				break
			}
		}

		fmt.println("Found:", found)
		if found {
			fmt.println(operators)
			totals += expected_result
		}
	}

	fmt.println("Total:", totals)
}
