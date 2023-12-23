defmodule PuzzleNode do
  defstruct [:label, :left, :right]

  def parse(str) do
    [label, edge_string] = String.split(str, "=", trim: true)
    [left, right] = String.replace(edge_string, ~r/[\(\)]/, "") |> String.split(",", trim: true)

    %PuzzleNode{label: String.trim(label), left: String.trim(left), right: String.trim(right)}
  end
end

defmodule Solver do
  defstruct [:instructions, :node_map]

  def parse(str) do
    [instruction_str, nodes_str] = String.split(str, "\n\n")
    instructions = String.graphemes(instruction_str) |> Enum.reject(&(&1 == " "))

    node_map =
      String.split(nodes_str, "\n")
      |> Enum.map(&PuzzleNode.parse/1)
      |> Enum.reduce(%{}, fn node, acc ->
        Map.put(acc, node.label, node)
      end)

    %Solver{instructions: instructions, node_map: node_map}
  end

  def find_distance(
        %Solver{instructions: instructions, node_map: node_map},
        start_labels,
        target_pattern
      ) do
    start_labels
    |> Enum.map(fn start_label ->
      instructions
      |> Stream.cycle()
      |> Enum.reduce_while({start_label, 0}, fn instruction, {label, count} ->
        if String.match?(label, target_pattern) do
          {:halt, count}
        else
          node = node_map[label]

          next_label =
            case instruction do
              "L" -> node.left
              "R" -> node.right
            end

          {:cont, {next_label, count + 1}}
        end
      end)
    end)
  end

  def part_1(solver) do
    start_label = "AAA"
    target_label = ~r/ZZZ/
    find_distance(solver, [start_label], target_label) |> hd()
  end

  def part_2(solver) do
    solver.node_map
    |> Map.keys()
    |> Enum.filter(&String.match?(&1, ~r/..A/))
    |> then(fn start_labels ->
      find_distance(solver, start_labels, ~r/..Z/)
    end)
    |> ExtraMath.lcm_of_list()

    # |> Enum.product()
  end
end

defmodule ExtraMath do
  def lcm_of_list(numbers) when is_list(numbers) do
    Enum.reduce(numbers, 1, &lcm/2)
  end

  defp lcm(a, b) when a > 0 and b > 0 do
    div(a * b, gcd(a, b))
  end

  defp gcd(a, 0), do: a
  defp gcd(a, b), do: gcd(b, rem(a, b))
end

solver = File.read!("./input.txt") |> Solver.parse()
Solver.part_1(solver) |> IO.inspect(label: "Part 1")
Solver.part_2(solver) |> IO.inspect(label: "Part 2")
