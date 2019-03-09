defmodule Tinker.Buttons.Shuffle do
  use Tinker.Button, pin_id: 16

  def pressed(_event), do: IO.puts "Shuffle!"

  def released(%{duration: duration}) do
    Logger.debug("Shuffle was depressed for #{duration}ms")
  end
end
