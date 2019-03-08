defmodule Tinker.Buttons.PlayPause do
  @behaviour Tinker.Button
  use GenServer
  require Logger

  alias Circuits.GPIO

  #use Tinker.Button, pin: 27

  @state_down 0
  @state_up 1

  @impl true
  def pin_id, do: 26

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(stack) do
    Logger.debug "Opening GPIO pin #{pin_id()}"
    with {:ok, gpio} <- GPIO.open(pin_id(), :input, pull_mode: :pullup),
         :ok <- GPIO.set_interrupts(gpio, :both, receiver: __MODULE__)
    do
      Logger.debug "Monitoring play/pause button"
      {:ok, %{gpio_pid: gpio}}
    else
      error -> {:error, error}
    end
  end

  @impl true
  def handle_info({:circuits_gpio, _pin_id, timestamp, value}, state) do
    handle_button_state(value, state)

    new_state =
      state
      |> Map.put(:value, value)
      |> Map.put(:last_change, timestamp)

    {:noreply, new_state}
  end

  @impl true
  def handle_call(:gpio_pid, _from, state) do
    {:reply, state.gpio_pid, state}
  end

  def handle_button_state(@state_down, _state), do: IO.puts "Button pressed"
  def handle_button_state(@state_up, %{last_change: last_change} = state) do
    diff =
      (host_uptime() - last_change)
      |> System.convert_time_unit(:nanosecond, :millisecond)
    IO.puts("Button was depressed for #{diff}ms")
  end
  def handle_button_state(_, _), do: nil

  def gpio_pid do
    GenServer.call(__MODULE__, :gpio_pid)
  end

  # Get system uptime in nanoseconds
  defp host_uptime do
    "/proc/uptime"
    |> File.stream!([], :line)
    |> Enum.at(0)
    |> String.replace(~r/\D/, "")
    |> String.to_integer
  end
end
