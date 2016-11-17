defmodule ScramThingMagic.Reader do
  use GenServer
  require Logger

  defstruct ~w[feed player port last_play]a

  @table %{
    "300833B2DDD9014000000000" => "kaylee",
    "35E0170102000000008A6B05" => "apollo"
  }

  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  def connect(reader) do
    GenServer.cast(reader, :connect)
  end

  def init(config) do
    connect(self)
    reader = %__MODULE__{
      feed: Keyword.fetch!(config, :feed),
      player: Keyword.fetch!(config, :player),
      last_play: now
    }
    {:ok, reader}
  end

  def handle_cast(:connect, reader) do
    Logger.debug("Connecting…")
    port = Port.open({:spawn, reader.feed}, [:binary, :exit_status])
    true = Port.connect(port, self)
    {:noreply, %__MODULE__{reader | port: port}}
  end

  def handle_info({port, {:data, data}}, reader)
  when is_port(port) do
    [_match, epc] = Regex.run(~r{\AEPC:(\S+)\b}, data)
    chip = @table[epc]
    new_reader =
      if chip && now - reader.last_play > 7 do
        Logger.info("Detected #{chip}.")
        sound = Path.expand("../../priv/#{chip}.mp3", __DIR__)
        Task.start(fn ->
          Logger.debug("Playing sound...")
          try do
            System.cmd(reader.player, [sound])
          rescue
            error -> Logger.debug("Play error:  #{inspect error}.")
          end
          Logger.debug("Sound finished.")
        end)
        %__MODULE__{reader | last_play: now}
      else
        Logger.debug("Ignoring #{epc}.")
        reader
      end
    {:noreply, new_reader}
  end
  def handle_info({port, {:exit_status, _exit_status}}, reader)
  when is_port(port) do
    connect(self)
    {:noreply, %__MODULE__{reader | port: nil}}
  end
  def handle_info(message, reader) do
    Logger.debug("Unexpected message:  #{inspect message}")
    {:noreply, reader}
  end

  defp now do
    System.monotonic_time(:seconds)
  end
end
