defmodule Tinker.Buzzer do
  use GenServer
  require Logger
  alias Circuits.GPIO

  def start_link([opts]) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    Logger.info("Opening buzzer on GPIO pin #{opts[:pin_id]}")

    case GPIO.open(opts[:pin_id], :output) do
      {:ok, gpio} -> {:ok, %{gpio_pid: gpio}}
      error -> {:error, error}
    end
  end

  def beep(duration \\ 50) do
    GenServer.cast(__MODULE__, {:beep, duration})
  end

  @impl true
  def handle_cast({:beep, duration}, state) do
    Logger.debug "Beep for #{duration}ms"

    GPIO.write(state.gpio_pid, 1)
    :timer.sleep(duration)
    GPIO.write(state.gpio_pid, 0)

    {:noreply, state}
  end
end
