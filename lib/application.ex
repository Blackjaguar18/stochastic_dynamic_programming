defmodule SDP.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      {SDP.GlobalParameters, [GlobalParameters]},
      {SDP.FirstWorker, [FirstWorker]},
      {SDP.MiddleWorker, [MiddleWorker]},
      {SDP.LastWorker, [LastWorker]}
    ]

    opts = [strategy: :one_for_one, name: SDP.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
