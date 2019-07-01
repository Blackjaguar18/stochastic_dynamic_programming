defmodule SDP.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      {SDP.GlobalParameters, [:global]},
      {SDP.FirstWorker, [A]},
      {SDP.MiddleWorker, [B]},
      {SDP.MiddleWorker, [C]},
      {SDP.MiddleWorker, [D]},
      {SDP.LastWorker, [E]}
    ]

    opts = [strategy: :one_for_one, name: SDP.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
