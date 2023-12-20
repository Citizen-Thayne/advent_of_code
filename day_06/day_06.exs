defmodule Solver do
  defp part_01_parse(str) do
    [time_line, distance_line] = String.split(str, "\n")

    times =
      time_line
      |> String.split(":")
      |> List.last()
      |> String.split(" ", trim: true)
      |> Enum.map(&String.to_integer/1)

    distances =
      distance_line
      |> String.split(":")
      |> List.last()
      |> String.split(" ", trim: true)
      |> Enum.map(&String.to_integer/1)

    Enum.zip_with([times, distances], fn [time, distance] -> Race.new(time, distance) end)
  end

  defp part_02_parse(str) do
    [time_line, distance_line] = String.split(str, "\n")

    time =
      String.split(time_line, ":", trim: true)
      |> List.last()
      |> String.replace(" ", "")
      |> String.to_integer()

    distance =
      String.split(distance_line, ":", trim: true)
      |> List.last()
      |> String.replace(" ", "")
      |> String.to_integer()

    Race.new(time, distance)
  end

  def part_1(input) do
    part_01_parse(input)
    |> Enum.map(fn race ->
      number_of_ways = Race.max_hold_time(race) - Race.min_hold_time(race) + 1
    end)
    |> Enum.product()
  end

  def part_2(input) do
    race = part_02_parse(input)

    Race.max_hold_time(race) - Race.min_hold_time(race) + 1
  end
end

defmodule Race do
  defstruct [:time, :distance]

  def new(time, distance) do
    %Race{time: time, distance: distance}
  end

  def min_hold_time(%Race{time: time, distance: distance}) do
    ((time - :math.sqrt(time ** 2 - 4 * distance)) / 2)
    |> :math.ceil()
  end

  def max_hold_time(%Race{time: time, distance: distance}) do
    ((time + :math.sqrt(time ** 2 - 4 * distance)) / 2)
    |> :math.floor()
  end
end

input = File.read!("./input.txt")

Solver.part_1(input) |> IO.inspect()
Solver.part_2(input) |> IO.inspect()
