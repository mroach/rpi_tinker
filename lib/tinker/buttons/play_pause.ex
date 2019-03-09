defmodule Tinker.Buttons.PlayPause do
  use Tinker.Button, pin_id: 26

  def pressed(_event), do: IO.puts "Play!"

  def released(%{duration: duration}) do
    Logger.debug("Play was depressed for #{duration}ms")
  end
end
