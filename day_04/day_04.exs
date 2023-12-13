defmodule Card do
  defstruct [:winning_set, :numbers]

  def parse(str) do
    [_, winning_number_str, number_str] = String.split(str, [":", "|"])

    winning_set =
      winning_number_str
      |> String.split(" ", trim: true)
      |> Enum.map(&String.to_integer/1)
      |> MapSet.new()

    numbers = number_str |> String.split(" ", trim: true) |> Enum.map(&String.to_integer/1)

    %Card{
      winning_set: winning_set,
      numbers: numbers
    }
  end

  def recurse_score(originals, cards, count) do
    index = Enum.find_index(cards, &(&1 > 0))

    if index == nil do
      count
    else
      card_count = Enum.at(cards, index)
      score = Enum.at(originals, index) |> Card.count_score()
      increasing_range = (index + 1)..(index + score)//1

      next_cards =
        Enum.reduce(increasing_range, cards, fn i, acc ->
          List.update_at(acc, i, &(&1 + card_count))
        end)
        |> List.update_at(index, fn _ -> 0 end)

      next_count = count + card_count
      recurse_score(originals, next_cards, next_count)
    end
  end

  def count_score(%Card{winning_set: winning_set, numbers: numbers}) do
    numbers
    |> Enum.filter(&MapSet.member?(winning_set, &1))
    |> length()
  end

  def power_score(card) do
    count_score(card)
    |> case do
      0 -> 0
      x -> :math.pow(2, x - 1)
    end
    |> round
  end
end

cards =
  File.read!("./input.txt")
  |> String.split("\n")
  |> Enum.map(&Card.parse/1)

sum_score =
  cards
  |> Enum.map(&Card.power_score/1)
  |> Enum.sum()
  |> round()

IO.puts("Part 1 Score: #{sum_score}")

starting_cards = List.duplicate(1, length(cards))
recursive_score = Card.recurse_score(cards, starting_cards, 0)
IO.puts("Part 2 score: #{recursive_score}")
