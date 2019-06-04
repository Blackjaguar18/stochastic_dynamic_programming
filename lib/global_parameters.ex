defmodule SDP.GlobalParameters do
  @moduledoc """
  Process used to hold any global parameters required for the problem.
  Other process can send messages to this process to obtain the values of
  the parameters. This process comes in handy when a range of expirements
  are defined where the parameters should be changed often.
  """
  use GenServer

  @doc """
  Callback defining how to the process is started and named.
  """
  def child_spec(arg) do
    %{id: :global_worker, start: {SDP.GlobalParameters, :start_link, arg}}
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
  Endpoint to set the state of this process to be equal to a map of parameters.
  Replies with :done if successfull.
  """
  def handle_call({:set_parameters, parameters}, _from, _state) do
    {:reply, :done, parameters}
  end

  @doc """
  Endpoint to retrieve and return a given parameter.
  """
  def handle_call({:return_parameter, parameter}, _from, state) do
    parameter = Map.get(state, parameter)
    {:reply, parameter, state}
  end

  @doc """
  Endpoint to reset the state of the process, resetting its state and thus removing the values of the parameters.
  """
  def handle_call(:clean, _from, _state) do
    {:reply, :done, %{}}
  end
end
