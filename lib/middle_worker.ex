defmodule SDP.MiddleWorker do
  @moduledoc """
  This module represents on of the processes that are spinned up with the task
  to hold state with regards to the initial first stage of the SDP procedure.
  """
  use GenServer

  @doc """
  Callback defining how to the process is started and named.
  """
  def child_spec(arg) do
    %{id: :middle_worker, start: {SDP.MiddleWorker, :start_link, arg}}
  end

  @doc """
  Callback that runs the second the process is spinned up. For now it only
  provides the module that should be run within the process and its name so
  that other processes can communicate with it.
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  @doc """
  Required callback, has no influence for now. Can be used to initialize the state
  of the process.
  """
  def init(state) do
    {:ok, state}
  end

  @doc """
  If any other process sends a message to this process with the structure
  {:start, worker}, where worker represents the name of a process, then this
  process will request the bellman values from the given process and start to
  execute the optimization equations using these future values and storing the
  outcome in its state.
  Finally, a response is sent with the state after the calculations are done.
  """
  def handle_call({:start, worker}, _from, _state) do
    future_optimal_values = GenServer.call(worker, :return_state)
    state = SDP.bellman_middle(future_optimal_values)

    {:reply, :done, state}
  end

  @doc """
  Endpoint for other processes to retrieve the state, which contains the bellman
  values, used in other stages to determine future expected costs in the SDP procedure.
  """
  def handle_call(:return_state, _from, state) do
    {:reply, state, state}
  end

  @doc """
  Endpoint to reset the state of the process, resetting its state and thus removing the bellman values from its state.
  """
  def handle_call(:clean, _from, _state) do
    {:reply, :done, %{}}
  end
end
