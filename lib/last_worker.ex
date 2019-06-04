defmodule SDP.LastWorker do
  @moduledoc """
  This module represents on of the processes that are spinned up with the task
  to hold state with regards to the initial first stage of the SDP procedure.
  """
  use GenServer

  @doc """
  Callback defining how to the process is started and named.
  """
  def child_spec(arg) do
    %{id: :last_worker, start: {SDP.LastWorker, :start_link, arg}}
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
  Sending the :start message to this process initiates the first stage of the
  SDP procedure, and sets the state of this process to be equal to the bellman
  values calculated for this first stage.
  """
  def handle_call(:start, _from, _state) do
    state = SDP.bellman_final()

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
