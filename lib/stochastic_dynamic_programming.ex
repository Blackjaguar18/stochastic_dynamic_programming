defmodule SDP do
  @moduledoc """
  Documentation for StochasticDynamicProgramming.
  """
  @doc """
  The probability that a random uniform variable is equal to x.
  """
  def pdf(x) do
    cond do
      x >= fetch(:lower_bound_uniform) and x <= fetch(:upper_bound_uniform) ->
        1 / fetch(:total_number_of_values)

      true ->
        0
    end
  end

  @doc """
  The probability that a discrete uniformly distributed random variable
  is more than or equal to x, given the lower bound of the interval a and the number of values n.
  """
  def cdf(x) do
    cond do
      x >= fetch(:lower_bound_uniform) and x <= fetch(:upper_bound_uniform) ->
        (x - fetch(:lower_bound_uniform) + 1) / fetch(:total_number_of_values)

      x < fetch(:lower_bound_uniform) ->
        0

      x > fetch(:upper_bound_uniform) ->
        1
    end
  end

  @doc """
  The probability that a discrete uniformly distributed random variable
  is less than or equal to x, given the lower bound of the interval a and the number of values n.
  """
  def inverse_cdf(x) do
    cond do
      x >= fetch(:lower_bound_uniform) and x <= fetch(:upper_bound_uniform) ->
        1 - cdf(x) + 1 / fetch(:total_number_of_values)

      x > fetch(:upper_bound_uniform) ->
        0

      x < fetch(:lower_bound_uniform) ->
        1
    end
  end

  @doc """
  The probability that the stock level in the next period is equal to x.
  """
  def pdf_x(x_i, x, z, k) when x_i == 0 do
    x
    |> stock_after_transformations(z, k)
    |> inverse_cdf()
  end

  def pdf_x(x_i, x, z, k) when x_i > 0 do
    stock_after_transformations = stock_after_transformations(x, z, k)

    if x_i >= stock_after_transformations - fetch(:upper_bound_uniform) and
         x_i <= stock_after_transformations and x_i >= fetch(:min_x) and x_i <= fetch(:max_x) do
      1 / fetch(:total_number_of_values)
    else
      0
    end
  end

  @doc """
  In any other case, the result is 0.
  """
  def pdf_x(_x_i, _x, _z, _k), do: 0

  @doc """
  The stock level after any policy driven transformations up or down has been made.
  """
  def stock_after_transformations(x, z, k) do
    x - max(x - z, 0) + max(k - x, 0)
  end

  @doc """
  Costs arising in the final period.
  """
  def costs_final(x, z, k, d) do
    max(d - stock_after_transformations(x, z, k), 0) * fetch(:c1) + max(k - x, 0) * fetch(:c2) +
      max(x - z, 0) * fetch(:c3) + max(stock_after_transformations(x, z, k) - d, 0) * fetch(:c4)
  end

  @doc """
  Costs arising in any period other than the first or the last.
  """
  def costs_middle(x, z, k, d) do
    max(d - stock_after_transformations(x, z, k), 0) * fetch(:c1) + max(k - x, 0) * fetch(:c2) +
      max(x - z, 0) * fetch(:c3)
  end

  @doc """
  The direct expected costs in the final period
  """
  def expected_costs_final(x, z, k) do
    Enum.reduce(fetch(:lower_bound_uniform)..fetch(:upper_bound_uniform), 0, fn d, count ->
      pdf(d) * costs_final(x, z, k, d) + count
    end)
  end

  @doc """
  The direct expected costs in any period other than the first and the final
  """
  def expected_costs_middle(x, z, k) do
    Enum.reduce(fetch(:lower_bound_uniform)..fetch(:upper_bound_uniform), 0, fn d, count ->
      pdf(d) * costs_middle(x, z, k, d) + count
    end)
  end

  @doc """
  Returns the different possible configurations of the stock level of x and policy parameters.
  """
  def possible_values() do
    for x <- fetch(:min_x)..fetch(:max_x),
        z <- fetch(:min_x)..fetch(:max_x),
        k <- fetch(:min_x)..fetch(:max_x),
        k <= z do
      %{x: x, z: z, k: k}
    end
  end

  @doc """
  Computes the bellman values for the first iteration of the SDP procedure, that is: the final period.
  """
  def bellman_final() do
    possible_values()
    |> Enum.map(fn %{x: x, z: z, k: k} ->
      %{
        x: x,
        z: z,
        k: k,
        value: expected_costs_final(x, z, k)
      }
    end)
    |> Enum.reduce(%{}, fn %{x: x, value: v, k: k, z: z}, map ->
      Map.update(
        map,
        x,
        [%{value: v, k: k, z: z}],
        &[%{value: v, k: k, z: z} | &1]
      )
    end)
    |> Enum.map(fn {x, values} ->
      {x, find_min_values(values)}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Computes the bellman values for any stage in between the first and the last, using the bellman values of the future stage.
  """
  def bellman_middle(bellman_values_next_stage) do
    possible_values()
    |> Enum.map(fn %{x: x, z: z, k: k} ->
      %{
        x: x,
        z: z,
        k: k,
        value:
          expected_costs_middle(x, z, k) +
            expected_future_costs(x, z, k, bellman_values_next_stage)
      }
    end)
    |> Enum.reduce(%{}, fn %{x: x, value: v, k: k, z: z}, map ->
      Map.update(map, x, [%{value: v, k: k, z: z}], &[%{value: v, k: k, z: z} | &1])
    end)
    |> Enum.map(fn {x, values} ->
      {x, find_min_values(values)}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Computes the bellman values for the final stage of the SDP procedure, that is: the initial period.
  """
  def bellman_initial(bellman_values_next_stage) do
    values_of_x =
      for x <- fetch(:min_x)..fetch(:max_x) do
        x
      end

    values_of_x
    |> Enum.map(fn x ->
      %{
        x: x,
        value: bellman_value(x, bellman_values_next_stage)
      }
    end)
    |> find_min_values()
  end

  @doc """
  Computes the expected future costs based upon bellman values for the next stage and the probability distribution of the stock level of x in the next period.
  """
  def expected_future_costs(x, z, k, bellman_values_next_stage) do
    Enum.reduce(fetch(:min_x)..fetch(:max_x), 0, fn v, count ->
      pdf_x(v, x, z, k) * bellman_value(v, bellman_values_next_stage) + count
    end)
  end

  @doc """
  Retrieves the value corresponding to a certain stock level v.
  """
  def bellman_value(v, optimal_values) do
    {:ok, [%{value: value} | _]} = Map.fetch(optimal_values, v)
    value
  end

  @doc """
  Finds the minimum values or list of values in a list bellman values.
  """
  def find_min_values(values) do
    Enum.reduce(values, [%{value: :init}], fn %{value: value} = values,
                                              [%{value: current_lowest} | _] = current ->
      cond do
        value > current_lowest ->
          current

        value == current_lowest ->
          [values | current]

        value < current_lowest ->
          [values]

        current_lowest == :init ->
          [values]
      end
    end)
  end

  @doc """
  Retrieves the value for a provided parameter from the process holding these parameters.
  """
  def fetch(parameter) when is_atom(parameter) do
    GenServer.call(:global, {:return_parameter, parameter})
  end
end
