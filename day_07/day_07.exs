defmodule Solver do
  def part_01(input) do
    solve(input, false)
  end

  def part_02(input) do
    solve(input, true)
  end

  def solve(input, joker) do
    input
    |> String.split("\n")
    |> Enum.map(fn line ->
      [hand_str, bid_str] = String.split(line, " ")
      bid = String.to_integer(bid_str)
      hand = Hand.parse(hand_str)
      {hand, bid}
    end)
    |> Enum.sort(fn {a_hand, _}, {b_hand, _} -> Hand.compare(a_hand, b_hand, joker) end)
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.map(fn {{_, bid}, index} -> bid * (index + 1) end)
    |> Enum.sum()
  end
end

defmodule Hand do
  defstruct [:cards]

  @hand_kind_order [
    :high_card,
    :one_pair,
    :two_pair,
    :three_oak,
    :full_house,
    :four_oak,
    :five_oak
  ]

  @card_order [
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "T",
    "J",
    "Q",
    "K",
    "A"
  ]

  def parse(str) do
    %Hand{
      cards: String.split(str, "", trim: true)
    }
  end

  def compare_hand_type(a, b, joker) do
    a_index = Enum.find_index(@hand_kind_order, &(&1 == type(a, joker)))
    b_index = Enum.find_index(@hand_kind_order, &(&1 == type(b, joker)))

    case a_index - b_index do
      x when x > 0 -> :gt
      x when x < 0 -> :lt
      x when x == 0 -> :eq
    end
  end

  def card_order_strength(label, joker) do
    card_order =
      if joker do
        Enum.reject(@card_order, &(&1 == "J"))
        |> List.insert_at(0, "J")
      else
        @card_order
      end

    Enum.find_index(card_order, &(&1 == label))
  end

  def compare_hand_order(%Hand{cards: a_cards}, %Hand{cards: b_cards}, joker) do
    Enum.zip([a_cards, b_cards])
    |> Enum.map(fn {a, b} -> {card_order_strength(a, joker), card_order_strength(b, joker)} end)
    |> Enum.find_value(fn {a, b} ->
      case a - b do
        x when x > 0 -> :a
        x when x < 0 -> :b
        _ -> false
      end
    end)
    |> case do
      :a -> true
      :b -> false
      _ -> true
    end
  end

  def compare(a, b, joker \\ false) do
    case compare_hand_type(a, b, joker) do
      :gt -> true
      :lt -> false
      :eq -> compare_hand_order(a, b, joker)
    end
  end

  def type(%Hand{cards: cards}, joker) do
    top_2 =
      Enum.frequencies(cards)
      |> then(fn freq ->
        if joker do
          {joker_count, without_joker} = Map.pop(freq, "J", 0)

          if joker_count == 5 do
            %{"K" => 5}
          else
            {max, _} = Enum.max_by(without_joker, fn {_, count} -> count end)
            Map.update!(without_joker, max, &(&1 + joker_count))
          end
        else
          freq
        end
      end)
      |> Map.values()
      |> Enum.sort(:desc)
      |> Enum.take(2)

    case top_2 do
      [5] ->
        :five_oak

      [4, _] ->
        :four_oak

      [3, 2] ->
        :full_house

      [3, _] ->
        :three_oak

      [2, 2] ->
        :two_pair

      [2, _] ->
        :one_pair

      [_, _] ->
        :high_card
    end
  end
end

input = File.read!("./input.txt")

Solver.part_01(input) |> IO.inspect(label: "Solution 1")
Solver.part_02(input) |> IO.inspect(label: "Solution 2")
