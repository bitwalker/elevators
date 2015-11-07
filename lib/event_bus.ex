defmodule Elevators.EventBus do
  @moduledoc """
  Proxies user-initiated and elevator-initated events to handlers
  """

  def start_link(handlers) do
    result = GenEvent.start_link(name: __MODULE__)
    Enum.each(handlers, fn {name, arg} -> add_handler(name, arg) end)
    result
  end

  def add_handler(module, args) do
    GenEvent.add_handler(__MODULE__, module, args)
  end

  @doc """
  An elevator has been initialized.
  """
  def initialized(id, state) do
    GenEvent.notify(__MODULE__, {:initialized, id, state})
  end

  @doc """
  The doors of an elevator have opened.
  """
  def open(id) do
    GenEvent.notify(__MODULE__, {:open, id})
  end

  @doc """
  The doors of an elevator have closed.
  """
  def closed(id) do
    GenEvent.notify(__MODULE__, {:closed, id})
  end

  @doc """
  An elevator has started moving towards floor `goal`
  """
  def moving(id, goal) do
    GenEvent.notify(__MODULE__, {:moving, id, goal})
  end

  @doc """
  An elevator is approaching it's next stop
  """
  def approaching(id, goal) do
    GenEvent.notify(__MODULE__, {:approaching, id, goal})
  end

  @doc """
  An elevator is passing a floor
  """
  def passing(id, goal) do
    GenEvent.notify(__MODULE__, {:passing, id, goal})
  end

  @doc """
  An elevator has stopped at a floor.
  """
  def arrived(id, goal) do
    GenEvent.notify(__MODULE__, {:arrived, id, goal})
  end

  @doc """
  An elevator is being called
  """
  def called(id, from, to) do
    GenEvent.notify(__MODULE__, {:called, id, from, to})
  end

end
