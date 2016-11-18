defmodule ScramThingMagic.Player do
  use GenServer
  require Logger

  defstruct ~w[player timer]a

  def start_link(player) do
    GenServer.start_link(__MODULE__, player, name: __MODULE__)
  end

  def play(sound) do
    GenServer.cast(__MODULE__, {:play, sound})
  end

  def init(player) do
    {:ok, %__MODULE__{player: player}}
  end

  def handle_cast({:play, sound}, player) do
    Logger.debug("Player started…")
    port = Port.open({:spawn, "#{player.player} #{sound}"}, [:exit_status])
    timer = Process.send_after(self, {:close, port}, 6_000)
    {:noreply, %__MODULE__{player | timer: timer}}
  end

  def handle_info({port, {:exit_status, _exit_status}}, player)
  when is_port(port) do
    Logger.debug("Player exited.")
    Process.cancel_timer(player.timer)
    {:noreply, %__MODULE__{player | timer: nil}}
  end
  def handle_info({:close, port}, player) when is_port(port) do
    try do
      Port.close(port)
      Logger.debug("Player closed.")
    rescue
      error -> Logger.debug("Error while closing:  #{inspect error}")
    end
    {:noreply, %__MODULE__{player | timer: nil}}
  end
  def handle_info(message, player) do
    Logger.debug("Unexpected message:  #{inspect message}")
    {:noreply, player}
  end
end
