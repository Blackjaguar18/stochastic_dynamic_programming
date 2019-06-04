alias SDP.{FirstWorker, MiddleWorker, LastWorker, GlobalParameters}

GlobalParameters.start_link(:global)
FirstWorker.start_link(:first)
MiddleWorker.start_link(:middle)
LastWorker.start_link(:last)

for x <- [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50] do
  :done =
    GenServer.call(
      :global,
      {:set_parameters,
       %{
         min_x: 0,
         max_x: 27,
         c1: x,
         c2: 1,
         c3: 1,
         c4: 1,
         lower_bound_uniform: 0,
         upper_bound_uniform: 3,
         total_number_of_values: 4
       }}
    )

  :done = GenServer.call(:last, :start, 50000)
  :done = GenServer.call(:middle, {:start, :last}, 50000)
  :done = GenServer.call(:first, {:start, :middle}, 50000)
  IO.inspect(GenServer.call(:first, :return_state))

  GenServer.call(:last, :clean)
  GenServer.call(:middle, :clean)
  GenServer.call(:first, :clean)
  GenServer.call(:global, :clean)
end
