input_path = "./input.txt"

input = File.read!(input_path)

parse_id = fn s ->
  [[_, id]] = Regex.scan(~r/Game (\d+)/, s)
  String.to_integer(id)
end

extract_cube_score = fn s, color ->
  regex = Regex.compile!("([0-9]+) #{color}")
  match = Regex.scan(regex, s) |> Enum.at(0)

  case match do
    nil -> 0
    found -> Enum.at(found, 1) |> String.to_integer()
  end
end

max_red = 12
max_green = 13
max_blue = 14

valid_game? = fn pulls ->
  Enum.all?(pulls, fn pull ->
    %{red: red, green: green, blue: blue} = pull
    red <= max_red && green <= max_green && blue <= max_blue
  end)
end

min_possible = fn pulls ->
  initial = %{:red => 0, :blue => 0, :green => 0}

  Enum.reduce(pulls, initial, fn pull, acc ->
    %{
      red: Enum.max([pull[:red], acc[:red]]),
      blue: Enum.max([pull[:blue], acc[:blue]]),
      green: Enum.max([pull[:green], acc[:green]])
    }
  end)
end

parse_cubes = fn s ->
  String.split(s, ";")
  |> Enum.map(fn cube_string ->
    red = extract_cube_score.(cube_string, "red")
    blue = extract_cube_score.(cube_string, "blue")
    green = extract_cube_score.(cube_string, "green")

    %{
      red: red,
      blue: blue,
      green: green
    }
  end)
end

results =
  String.split(input, "\n")
  |> Enum.map(fn line ->
    [id_string, cube_string] = String.split(line, ":")
    id = parse_id.(id_string)
    cubes = parse_cubes.(cube_string)

    valid = valid_game?.(cubes)
    power = min_possible.(cubes) |> Map.values() |> Enum.product()

    %{
      id: id,
      valid?: valid,
      power: power,
      cubes: cubes
    }
  end)

valid_id_sum =
  Enum.filter(results, &Map.get(&1, :valid?)) |> Enum.map(&Map.get(&1, :id)) |> Enum.sum()

max_score_power_sum =
  Enum.map(results, &Map.get(&1, :power)) |> Enum.sum()

IO.puts("Valid ID sum : #{valid_id_sum}")
IO.puts("Max Score Power Sum : #{max_score_power_sum}")
