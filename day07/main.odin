package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"

Equation :: struct {
	expected_result: int,
	operands:        [dynamic]int,
}

Operator :: enum {
	Add,
	Mul,
	Concat,
}

solve :: proc(equations: [dynamic]Equation, max_operator: Operator) -> int {
	defer free_all(context.temp_allocator)

	concat_acc: strings.Builder
	strings.builder_init_none(&concat_acc, context.temp_allocator)

	totals := 0
	for equation in equations {
		operands := equation.operands
		expected_result := equation.expected_result

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
				case Operator.Concat:
					strings.write_int(&concat_acc, acc)
					strings.write_int(&concat_acc, operands[i])
					acc = strconv.atoi(strings.to_string(concat_acc))
					strings.builder_reset(&concat_acc)
				}
			}
			if acc == expected_result {
				found = true
				break
			}

			for i := 0; i < len(operators); i += 1 {
				if operators[i] == max_operator {
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

		if found {
			totals += expected_result
		}
	}

	return totals
}

part1 :: proc(equations: [dynamic]Equation) {
	totals := solve(equations, Operator.Mul)
	fmt.println("part1:", totals)
}

part2 :: proc(equations: [dynamic]Equation) {
	totals := solve(equations, Operator.Concat)
	fmt.println("part2:", totals)
}

main :: proc() {
	data, ok := os.read_entire_file_from_filename("input.txt")
	assert(ok)
	defer delete(data)

	totals := 0

	equations := make([dynamic]Equation)
	defer {
		for equation in equations {
			delete(equation.operands)
		}
		delete(equations)
	}
	text := string(data)
	for line in strings.split_lines_iterator(&text) {
		line := line

		expected_result := 0
		operands: [dynamic]int
		first := true
		for bit in strings.split_iterator(&line, " ") {
			if first {
				first = false
				expected_result = strconv.atoi(bit[:len(bit) - 1])
				continue
			}
			append(&operands, strconv.atoi(bit))
		}

		append(&equations, Equation{expected_result, operands})
	}

	part1(equations)
	part2(equations)
}
