defmodule Helper do
  def is_symbol?(s) do
    symbol_pattern = ~r/[^\d\.]/
    String.match?(s, symbol_pattern)
  end

  def is_number?(str) do
    case Integer.parse(str) do
      :error -> false
      _ -> true
    end
  end
end

defmodule Coord do
  defstruct x: Integer, y: Integer

  def new(x, y) when is_integer(x) and x >= 0 and is_integer(y) and y >= 0 do
    %Coord{x: x, y: y}
  end
end

defmodule Block do
  defstruct start: Coord, length: Integer

  def content(block, schematic) do
    %{start: %{x: x, y: y}, length: length} = block

    Enum.at(schematic.rows, y) |> Enum.slice(x, length) |> Enum.join()
  end

  def adjacent(block, schematic) do
    %{start: %{x: start_x, y: start_y}, length: length} = block

    max_x = Schematic.max_x(schematic)
    left_x = Enum.max([start_x - 1, 0])
    end_x = start_x + length
    right_x = Enum.min([end_x, max_x])
    x_range = left_x..right_x

    max_y = length(schematic.rows) - 1
    top_y = Enum.max([start_y - 1, 0])
    bottom_y = Enum.min([start_y + 1, max_y])
    y_range = top_y..bottom_y

    Enum.flat_map(y_range, fn y ->
      Enum.map(x_range, fn x ->
        if y == start_y and x >= start_x and x < end_x do
          nil
        else
          Coord.new(x, y)
        end
      end)
      |> Enum.filter(& &1)
    end)
  end
end

defmodule Schematic do
  defstruct rows: [[]]

  def new(rows)
      when is_list(rows) and hd(rows) |> is_list() and hd(rows) |> hd() |> is_binary() do
    %Schematic{rows: rows}
  end

  def max_x(schematic) do
    length(hd(schematic.rows)) - 1
  end

  defp chunk_fn(char, coord, start) do
    case {char, start} do
      # nothing here
      {".", nil} ->
        {:cont, nil}

      # end of block
      {".", start} ->
        {:cont, %Block{start: start, length: coord.x - start.x}, nil}

      # start of block
      {char, nil} ->
        if Helper.is_symbol?(char) do
          # Just symbol
          {:cont, %Block{start: coord, length: 1}, nil}
        else
          # Start of number
          {:cont, coord}
        end

      # Mid block
      {char, start} ->
        if Helper.is_symbol?(char) do
          # Next to symbol
          {:cont,
           [
             %Block{start: start, length: coord.x - start.x},
             %Block{start: coord, length: 1}
           ], nil}
        else
          # Number continues
          {:cont, start}
        end
    end
  end

  def at(%Coord{x: x, y: y}, %Schematic{rows: rows}) do
    Enum.at(rows, y) |> Enum.at(x)
  end

  def blocks(schematic) do
    Enum.with_index(schematic.rows)
    |> Enum.flat_map(fn {row, y} ->
      Enum.with_index(row)
      |> Enum.chunk_while(
        nil,
        fn {char, x}, start ->
          coord = Coord.new(x, y)
          chunk_fn(char, coord, start)
        end,
        fn
          nil ->
            {:cont, nil}

          start ->
            {:cont, %Block{start: start, length: length(schematic.rows) - 1 - start.y}, nil}
        end
      )
      |> List.flatten()
    end)
  end
end

schematic =
  File.read!("./input.txt")
  |> String.split("\n")
  |> Enum.map(&String.graphemes(&1))
  |> Schematic.new()

blocks = Schematic.blocks(schematic)

nums_adjacent_to_symbol =
  blocks
  |> Enum.filter(fn block ->
    content = Block.content(block, schematic)

    adjacent =
      Block.adjacent(block, schematic) |> Enum.map(&Schematic.at(&1, schematic))

    Helper.is_number?(content) and Enum.any?(adjacent, &Helper.is_symbol?(&1))
  end)
  |> Enum.map(&Block.content(&1, schematic))
  |> Enum.map(&String.to_integer/1)

schema_powers =
  blocks
  |> Enum.filter(fn block -> Block.content(block, schematic) |> Helper.is_number?() end)
  |> Enum.flat_map(fn num_block ->
    Block.adjacent(num_block, schematic)
    |> Enum.filter(fn coord -> Schematic.at(coord, schematic) == "*" end)
    |> Enum.map(fn coord -> [coord, num_block] end)
  end)
  |> Enum.reduce(%{}, fn [coord, num_block], acc ->
    Map.update(acc, coord, [num_block], &(&1 ++ [num_block]))
  end)
  |> Map.values()
  |> Enum.filter(&(length(&1) > 1))
  |> Enum.map(fn num_blocks ->
    num_blocks
    |> Enum.map(&Block.content(&1, schematic))
    |> Enum.map(&String.to_integer/1)
  end)
  |> Enum.map(&Enum.product/1)
  |> Enum.sum()

IO.puts("Part 1: #{Enum.sum(nums_adjacent_to_symbol)}")
IO.puts("Part 2: #{schema_powers}")
