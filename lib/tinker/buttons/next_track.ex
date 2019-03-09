defmodule Tinker.Buttons.NextTrack do
  use Tinker.Button, pin_id: 5

  def pressed(_event), do: IO.puts "Next!"

  def released(%{duration: duration}) do
    Logger.debug("Next was depressed for #{duration}ms")
  end
end
