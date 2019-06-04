defmodule StochasticDynamicProgrammingTest do
  use ExUnit.Case
  doctest StochasticDynamicProgramming

  test "max/2 returns the second argument if it is higher than the first" do
    result = StochasticDynamicProgramming.max(2, 3)
    assert result == 3
  end

  test "max/2 returns the first argument if it is higher than the second" do
    result = StochasticDynamicProgramming.max(3, 2)
    assert result == 3
  end

  test "max/2 returns the input if the inputs are the same" do
    result = StochasticDynamicProgramming.max(2, 2)
    assert result == 2
  end

  test "min/2 returns the second argument if it is less than the first" do
    result = StochasticDynamicProgramming.min(2, 3)
    assert result == 2
  end

  test "min/2 returns the first argument if it is less than the second" do
    result = StochasticDynamicProgramming.min(3, 2)
    assert result == 2
  end

  test "min/2 returns the input if the inputs are the same" do
    result = StochasticDynamicProgramming.min(2, 2)
    assert result == 2
  end
end
