defmodule Tinker.RFIDHandler do
  def tag_scanned(val) do
    timestamp = DateTime.utc_now |> DateTime.to_iso8601
    line = [timestamp, val, "\n"] |> Enum.join(" ")
    File.write("rfid_log.txt", line, [:append])
  end
end
