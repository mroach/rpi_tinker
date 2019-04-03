defmodule Tinker.RFIDMonitor do
  @moduledoc """
  This server opens up the serial connection to the RFID reader and watches
  for card scanned events.
  Currently this is done in a loop, but eventually the goal is to have interrupts.

  When a card is scanned, a `tag_scanned` handler will be called.
  The card is scanned every 100ms (the tag scanning itself takes time too)
  so if you hold a card on the reader it will be "scanned" repeatedly.
  Anti-duplication or a delay for the same card should be introduced.
  """

  use GenServer
  alias Circuits.SPI
  require Logger

  @card_check_every_ms 100

  def start_link([args]) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Reference to the SPI to manually interact with the reader via `RC522`
  """
  def spi, do: GenServer.call(__MODULE__, :spi)

  @impl true
  def init(opts) do
    device = opts[:device] || default_spi_bus()
    tag_scanned = opts[:tag_scanned]

    IO.puts ""
    IO.inspect(opts)

    Logger.debug "Connecting to RC522 device on #{device}"
    {:ok, spi} = SPI.open(device)
    RC522.initialize(spi)

    hwver = RC522.hardware_version(spi)
    Logger.info "Connected to #{hwver.chip_type} reader version #{hwver.version}"

    schedule_card_check()

    {:ok, %{spi: spi, tag_scanned: tag_scanned}}
  end

  @impl true
  def terminate(_reason, state) do
    SPI.close(state.spi)
  end

  @impl true
  def handle_call(:spi, _from, %{spi: spi} = state), do: {:reply, spi, state}

  def handle_call(:read_tag_id, _from, %{spi: spi} = state) do
    {:ok, data} = RC522.read_tag_id(spi)
    tag_id = RC522.card_id_to_number(data)
    {:reply, tag_id, state}
  end

  def handle_info(:card_check, %{tag_scanned: handler, spi: spi} = state) do
    {:ok, data} = RC522.read_tag_id(spi)

    case process_tag_id(data) do
      {:ok, tag_id} ->
        Logger.debug "Found tag #{tag_id}. Dispatching to #{inspect(handler)}"
        handler.(tag_id)
      {:error, _} -> nil
    end

    schedule_card_check()

    {:noreply, state}
  end

  # if the response is a list with length of 5, that'll be the card ID
  # otherwise, no card is present or there was a problem reading it
  defp process_tag_id(data) when is_list(data) and length(data) == 5 do
    {:ok, RC522.card_id_to_number(data)}
  end
  defp process_tag_id(data), do: {:error, :nocard}

  defp default_spi_bus, do: SPI.bus_names |> Enum.at(0)

  defp schedule_card_check(delay \\ @card_check_every_ms) do
    Process.send_after(self(), :card_check, delay)
  end
end
