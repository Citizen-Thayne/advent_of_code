token_int_map = %{
  "0" => 0,
  "1" => 1,
  "2" => 2,
  "3" => 3,
  "4" => 4,
  "5" => 5,
  "6" => 6,
  "7" => 7,
  "8" => 8,
  "9" => 9,
  "zero" => 0,
  "one" => 1,
  "two" => 2,
  "three" => 3,
  "four" => 4,
  "five" => 5,
  "six" => 6,
  "seven" => 7,
  "eight" => 8,
  "nine" => 9
}

tokens = Map.keys(token_int_map)
pattern = "(?=(#{Enum.join(tokens, "|")}))"
regex = Regex.compile!(pattern)

input_path = "./input.txt"

extract_calibration_values = fn line ->
  parsed = Regex.scan(regex, line)
  first_token = List.first(parsed) |> List.last()
  last_token = List.last(parsed) |> List.last()
  left = Map.get(token_int_map, first_token)
  right = Map.get(token_int_map, last_token)
  left * 10 + right
end

lines = File.read!(input_path) |> String.split("\n")

Enum.map(lines, extract_calibration_values)
|> Enum.zip(lines)
|> IO.inspect()

Enum.map(lines, extract_calibration_values)
|> Enum.sum()
|> IO.inspect()
