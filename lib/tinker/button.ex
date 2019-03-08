defmodule Tinker.Button do
  @callback pin_id() :: Integer.t

  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end
end
