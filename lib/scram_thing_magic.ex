defmodule ScramThingMagic do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    feed = System.get_env("SCRAM_FEED") || raise "No feed"
    player = System.get_env("SCRAM_PLAYER") || raise "No player"

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: ScramThingMagic.Worker.start_link(arg1, arg2, arg3)
      worker(ScramThingMagic.Player, [[player]]),
      worker(ScramThingMagic.Reader, [[feed: feed]]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ScramThingMagic.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
