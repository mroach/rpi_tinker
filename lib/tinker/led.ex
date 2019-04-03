defmodule Tinker.LED do
  use GenServer
  require Logger
  alias Circuits.GPIO

  def start_link([opts]) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    Logger.info("Opening LED on GPIO pin #{opts[:pin_id]}")

    case GPIO.open(opts[:pin_id], :output) do
      {:ok, gpio} -> {:ok, %{gpio_pid: gpio}}
      error -> {:error, error}
    end
  end

  def blink_once(duration \\ 50) do
    GenServer.cast(__MODULE__, {:blink_once, duration})
  end

  def switch_on, do: GenServer.cast(__MODULE__, {:switch_on})
  def switch_off, do: GenServer.cast(__MODULE__, {:switch_off})

  @impl true
  def handle_cast({:blink_once, duration}, state) do
    Logger.debug "Blink for #{duration}ms"

    switch_on()
    :timer.sleep(duration)
    switch_off()

    {:noreply, state}
  end

  @impl true
  def handle_cast({:switch_on}, state) do
    GPIO.write(state.gpio_pid, 1)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:switch_off}, state) do
    GPIO.write(state.gpio_pid, 0)
    {:noreply, state}
  end
end
