defmodule Tinker.Application do
  use Application
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    children = [
      Tinker.Buttons.PlayPause,
      worker(Nerves.IO.RC522, [{Tinker.RFIDHandler, :tag_scanned}])
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
