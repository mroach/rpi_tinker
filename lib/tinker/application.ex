defmodule Tinker.Application do
  use Application
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    children = [
      Tinker.Buttons.PlayPause,
      Tinker.Buttons.PreviousTrack,
      Tinker.Buttons.NextTrack,
      Tinker.Buttons.Shuffle,
      {Tinker.Buzzer, [%{pin_id: 27}]},
      {Tinker.LED, [%{pin_id: 22}]},
      {Tinker.RFIDMonitor, [%{tag_scanned: &Tinker.RFIDHandler.tag_scanned/1}]}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
