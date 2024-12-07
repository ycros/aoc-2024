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

part1 :: proc(equations: [dynamic]Equation) {
	Operator :: enum {
		Add,
		Mul,
	}

	totals := 0
	for equation in equations {
		operands := equation.operands
		expected_result := equation.expected_result
		// fmt.print(operands)
		// fmt.println(" =", expected_result)

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

			// next_operator := Operator.Mul
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

		// fmt.println("Found:", found)
		if found {
			// fmt.println(operators)
			totals += expected_result
		}
	}

	fmt.println("part1:", totals)
	assert(totals == 2501605301465)
}


part2 :: proc(equations: [dynamic]Equation) {
	defer free_all(context.temp_allocator)
	Operator :: enum {
		Add,
		Mul,
		Concat,
	}

	concat_acc: strings.Builder
	strings.builder_init_none(&concat_acc, context.temp_allocator)

	totals := 0
	for equation in equations {
		operands := equation.operands
		expected_result := equation.expected_result
		// fmt.print(operands)
		// fmt.println(" =", expected_result)

		operators := make([]Operator, len(operands) - 1)
		defer delete(operators)
		for i := 0; i < len(operators); i += 1 {
			operators[i] = Operator.Add
		}

		found := false
		outer: for {
			// debug prints
			// fmt.println("operands:", operands)
			// fmt.println("operators:", operators)

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

			// next_operator := Operator.Mul
			for i := 0; i < len(operators); i += 1 {
				if operators[i] == Operator.Concat {
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

		// fmt.println("Found:", found)
		if found {
			// fmt.println(operators)
			totals += expected_result
		}
		// fmt.println("\n")
	}

	fmt.println("part2:", totals)
}

main :: proc() {
	data, ok := os.read_entire_file_from_filename("input.txt")
	assert(ok)
	defer delete(data)

	totals := 0

	equations := make([dynamic]Equation)
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
