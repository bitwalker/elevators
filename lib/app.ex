defmodule Elevators.App do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Elevators.Scheduler, [[]], [name: :elevator_scheduler, restart: :permanent]),
      worker(Elevators.EventBus, [[]], [restart: :permanent, shutdown: 1000]),
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
