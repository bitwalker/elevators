defmodule Elevators.Scheduler do
  use GenServer
  alias Elevators.Elevator
  alias Elevators.Scheduler.State
  alias Elevators.Status

  defmodule State do
    defstruct elevators: nil
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: :elevator_scheduler)
  end

  def init(_) do
    {:ok, %State{elevators: HashDict.new()}}
  end

  def handle_call({:create, id}, _from, %State{elevators: elevs} = state) do
    {:ok, pid} = Elevator.start_link([id: id])
    {:reply, {:ok, id}, %{state | :elevators => HashDict.put(elevs, id, pid)}}
  end
  def handle_call({:create, id, starting_floor}, _from, %State{elevators: elevs} = state) do
    {:ok, pid} = Elevator.start_link([id: id, floor: starting_floor])
    {:reply, {:ok, id}, %{state | :elevators => HashDict.put(elevs, id, pid)}}
  end

  def handle_call({:get_status, id}, _from, %State{elevators: elevs} = state) do
    case HashDict.get(elevs, id) do
      pid when is_pid(pid) ->
        {status, floor, goal} = :gen_fsm.sync_send_event(pid, :get_status)
        result = {:ok, %Status{id: id, pid: pid, floor: floor, goal: goal, state: status}}
        {:reply, result, state}
      _ ->
        {:reply, :noproc, state}
    end
  end
  def handle_call(_, _, state), do: {:reply, :error, state}

  def handle_cast({:step, id}, %State{elevators: elevs} = state) do
    case HashDict.get(elevs, id) do
      pid when is_pid(pid) ->
        :gen_fsm.send_event(pid, :step)
        {:noreply, state}
    end
  end

  def handle_cast({:update, id, new_id, floor, goal}, %State{elevators: elevs} = state) do
    case HashDict.get(elevs, id) do
      pid when is_pid(pid) ->
        :gen_fsm.send_event(pid, {:update, floor, goal})
        # Update id
        updated_elevs = elevs |> HashDict.delete(id) |> HashDict.put(new_id, pid)
        {:noreply, %{state | :elevators => updated_elevs}}
    end
  end

  def handle_cast({:pickup, id, from, to}, %State{elevators: elevs} = state) do
    case HashDict.get(elevs, id) do
      pid when is_pid(pid) ->
        :gen_fsm.send_event(pid, {:pickup, from, to})
        {:noreply, state}
    end
  end
  def handle_cast(_, state), do: {:noreply, state}
end
