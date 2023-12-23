defmodule Solver do
  defstruct [:history_sets]

  def parse(str) do
    %Solver{
      history_sets: String.split(str, "\n") |> Enum.map(&HistorySet.parse(&1))
    }
  end

  def part_1(solver) do
    solver.history_sets |> Enum.map(&HistorySet.final_value/1) |> Enum.sum()
  end

  def part_2(solver) do
    solver.history_sets
    |> Enum.map(&HistorySet.reverse/1)
    |> Enum.map(&HistorySet.final_value/1)
    |> Enum.sum()
  end
end

defmodule HistoryValues do
  defstruct([:values])

  def parse(str) do
    values = String.split(str, " ") |> Enum.map(&String.to_integer(&1))
    new(values)
  end

  def new(values) do
    %HistoryValues{values: values}
  end

  def next_value(%HistoryValues{values: values}) do
    values
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [a, b] -> b - a end)
    |> new
  end

  def final_value?(%HistoryValues{values: values}) do
    Enum.all?(values, &(&1 == 0))
  end

  def push(history, val) do
    %HistoryValues{history | values: history.values ++ [val]}
  end

  def last(history) do
    List.last(history.values)
  end

  def reverse(history) do
    %HistoryValues{values: Enum.reverse(history.values)}
  end
end

defmodule HistorySet do
  defstruct [:start, :full_history, :final_value]

  def parse(str) do
    start = HistoryValues.parse(str)
    build(start)
  end

  def build(start) do
    full_history = extrapolate_down([start]) |> extrapolate_up()
    final_value = full_history |> List.first() |> HistoryValues.last()
    %HistorySet{start: start, full_history: full_history, final_value: final_value}
  end

  def final_value(history_set) do
    history_set.final_value
  end

  def extrapolate_down(histories) do
    last = List.last(histories)

    if HistoryValues.final_value?(last) do
      histories
    else
      next = HistoryValues.next_value(last)
      (histories ++ [next]) |> extrapolate_down()
    end
  end

  def extrapolate_up(histories) do
    Enum.reverse(histories)
    |> Enum.map_reduce(0, fn history, acc ->
      last = HistoryValues.last(history)
      next_value = last + acc
      updated_history = HistoryValues.push(history, next_value)
      {updated_history, next_value}
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  def reverse(history_set) do
    start = HistoryValues.reverse(history_set.start)
    build(start)
  end
end

solver = File.read!("./input.txt") |> Solver.parse()

Solver.part_1(solver) |> IO.inspect(label: "Part 1")
Solver.part_2(solver) |> IO.inspect(label: "Part 2")
