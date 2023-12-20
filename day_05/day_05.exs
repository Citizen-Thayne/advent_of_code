defmodule SourceMapItem do
  defstruct [:dest_range_start, :src_range_start, :range_length]

  @opaque t :: %__MODULE__{
            dest_range_start: integer,
            src_range_start: integer,
            range_length: integer
          }

  def parse(str) do
    String.split(str, " ", trim: true)
    |> Enum.map(&String.to_integer/1)
    |> Enum.zip([:dest_range_start, :src_range_start, :range_length])
    |> Enum.into(%{}, fn {val, key} -> {key, val} end)
  end

  def src_interval(item) do
    Interval.new(item.src_range_start, item.range_length)
  end

  def dest_interval(item) do
    Interval.new(item.dest_range_start, item.range_length)
  end

  def shift_amount(item) do
    item.src_range_start - item.dest_range_start
  end

  @spec map(%SourceMapItem{}, non_neg_integer()) :: non_neg_integer()
  def map(map_item, x) do
    diff = x - map_item.src_range_start

    if diff >= 0 and diff < map_item.range_length do
      map_item.dest_range_start + diff
    end
  end

  def map_interval(map_item, interval) do
    src_interval = src_interval(map_item)
    shift = shift_amount(map_item)
    convert_interval = Interval.overlap(src_interval, interval)
    forward_interval = Interval.difference(interval, src_interval)
    shifted_interval = if convert_interval, do: Interval.shift(convert_interval, shift), else: nil

    case {forward_interval, shifted_interval} do
      {_, nil} -> [forward_interval]
      {nil, _} -> [shifted_interval]
      {_, _} -> [forward_interval, shifted_interval]
    end
  end

  def sorter(a, b) do
    a.src_range_start >= b.src_range_start
  end
end

defmodule SourceMap do
  defstruct [:source_type, :destination_type, :map]

  @opaque t :: %__MODULE__{
            source_type: String.t(),
            destination_type: String.t(),
            map: [SourceMapItem]
          }

  def parse(str) do
    [header | items] = String.split(str, "\n", trim: true)
    name = String.split(header, " ") |> hd()
    [source_type, destination_type] = String.split(name, "-to-")

    %SourceMap{
      source_type: source_type,
      destination_type: destination_type,
      map: Enum.map(items, &SourceMapItem.parse/1)
    }
  end

  @spec map(%SourceMap{}, non_neg_integer()) :: non_neg_integer()
  def map(source_map, x) do
    Enum.find_value(source_map.map, x, &SourceMapItem.map(&1, x))
  end

  def map_interval(source_map, interval) do
    Enum.flat_map(source_map.map, &SourceMapItem.map_interval(&1, interval))
    |> Enum.reject(&is_nil/1)
  end
end

defmodule Almanac do
  defstruct [:maps]
  @type t :: %__MODULE__{maps: [SourceMap]}

  @spec parse(String.t()) :: Almanac
  def parse(str) do
    maps =
      str
      |> String.split("\n\n")
      |> Enum.map(&SourceMap.parse/1)

    %Almanac{maps: maps}
  end

  @spec map(%Almanac{}, non_neg_integer()) :: non_neg_integer()
  def map(almanac, x) do
    almanac.maps
    |> Enum.take(1)
    |> Enum.reduce(x, fn source_map, acc ->
      SourceMap.map(source_map, acc)
    end)
  end

  def map_interval(almanac, interval) do
    Enum.reduce(almanac.maps, [interval], fn source_map, acc ->
      Enum.flat_map(acc, &SourceMap.map_interval(source_map, &1))
      |> Enum.concat(acc)
    end)
  end
end

defmodule Solver do
  defstruct [:seeds, :almanac]

  def parse(str) do
    [seeds_string | [almanac_string]] =
      String.split(str, "\n\n", parts: 2)

    seeds =
      String.split(seeds_string, ":")
      |> Enum.at(1)
      |> String.split(" ", trim: true)
      |> Enum.map(&String.to_integer/1)

    almanac = Almanac.parse(almanac_string)
    %Solver{seeds: seeds, almanac: almanac}
  end

  def part_1(solver) do
    solver.seeds
    |> Enum.map(&Almanac.map(solver.almanac, &1))
    |> Enum.min()
  end

  defp to_intervals(seeds) do
    seeds
    |> Enum.chunk_every(2)
    |> Enum.map(fn [start, length] ->
      Interval.new(start, length)
    end)
  end

  def part_2(solver) do
    solver.seeds
    |> to_intervals()
    |> Enum.flat_map(fn interval ->
      Almanac.map_interval(solver.almanac, interval)
    end)
    |> Enum.map(&Interval.head/1)
    |> Enum.min()
  end
end

defmodule Interval do
  defstruct [:start, :length]

  @spec new(integer(), non_neg_integer()) :: Interval
  def new(start, length) do
    %Interval{start: start, length: length}
  end

  def last(interval) do
    interval.start + interval.length - 1
  end

  def head(interval) do
    interval.start
  end

  def shift(interval, num) do
    new(interval.start + num, interval.length)
  end

  def equal?(a, b) do
    a.start == b.start and a.offset == b.offset
  end

  def overlap(a, b) do
    a_start = head(a)
    a_end = last(a)
    b_start = head(b)
    b_end = last(b)

    cond do
      a_start <= b_end and a_end >= b_start ->
        start = Enum.max([a_start, b_start])
        stop = Enum.min([a_end, b_end])

        new(start, stop - start + 1)

      true ->
        nil
    end
  end

  def difference(a, b) do
    a_start = head(a)
    a_end = last(a)
    b_start = head(b)
    b_end = last(b)

    cond do
      !overlap(a, b) ->
        a

      equal?(a, b) ->
        nil

      a_start < b_start ->
        new(a_start, b_start)

      a_start > b_start ->
        new(b_end, a_end)
    end
  end
end

solver =
  File.read!("./input.txt")
  |> Solver.parse()

part_1 =
  Solver.part_1(solver)

IO.puts("Part 1 solution: #{part_1}")

part_2 =
  Solver.part_2(solver)

IO.puts("Part 2 solution: #{part_2}")
