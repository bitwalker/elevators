defmodule Elevators do
  @moduledoc """
  Client API for the :elevators application
  """

  def create(id, starting_floor \\ 1) do
    GenServer.call(:elevator_scheduler, {:create, id, starting_floor})
  end

  def get_status(id) do
    GenServer.call(:elevator_scheduler, {:get_status, id})
  end

  def step(id) do
    GenServer.cast(:elevator_scheduler, {:step, id})
  end

  def update(id, new_id, floor, goal) do
    GenServer.cast(:elevator_scheduler, {:update, id, new_id, floor, goal})
  end

  def pickup(id, from, to) when from >= 1 and to >= 1 do
    GenServer.cast(:elevator_scheduler, {:pickup, id, from, to})
  end
end
