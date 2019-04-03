defmodule Tinker.RFIDHandler do
  def tag_scanned(tag_id) do
    timestamp = DateTime.utc_now |> DateTime.to_iso8601
    line = [timestamp, tag_id, "\n"] |> Enum.join(" ")
    IO.puts(line)
  end
end
