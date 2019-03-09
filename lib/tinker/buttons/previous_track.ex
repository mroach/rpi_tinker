defmodule Tinker.Buttons.PreviousTrack do
  use Tinker.Button, pin_id: 6

  def pressed(_event), do: IO.puts "Previous!"

  def released(%{duration: duration}) do
    Logger.debug("Previous was depressed for #{duration}ms")
  end
end
