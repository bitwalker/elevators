defmodule Elevators.Elevator do
  @moduledoc """
  Finite state machine representing an elevator.

  # Transitions

      event
        from -> to

  ## Open

    :open
      :closed -> :open
      :open   -> :open
      other   -> throws error

  ## Closed
    :closed
      :open  -> :closed
      :closed -> :closed
      other -> throws error

  ## Step
    :step
      :ready -> :ready
      :open  -> :closed
      :closed -> :moving
      :moving  -> :approaching
      :approaching -> :arrived
      :arrived -> :open

  ## Pickup
    :pickup
      current_state -> current_state

  ## Get Status

    :get_status
      current_state -> current_state
  """
  @behaviour :gen_fsm
  require Logger
  alias Elevators.Elevator.State

  defmodule State do
    defstruct id: nil, floor: 1, goal: [], status: :unknown, mode: :from
  end

  def start_link(opts) do
    id     = Keyword.get(opts, :id)
    floor  = Keyword.get(opts, :floor, 1)
    goal   = Keyword.get(opts, :goal, [])
    status = Keyword.get(opts, :status, :closed)
    :gen_fsm.start_link(__MODULE__, [id: id, floor: floor, goal: goal, status: status], [])
  end

  def init([id: id, floor: floor, goal: goal, status: status]) do
    Logger.info "Initializing a new #{status} elevator on floor #{floor}, with goal: `#{inspect goal}`"
    {:ok, status, %State{id: id, floor: floor, goal: goal, status: status}}
  end

  # Starts with doors closed
  def closed(:step, %State{floor: floor, mode: :from, goal: [{floor, _}|_]} = state) do
    {:next_state, :moving, %{state | :status => :moving, :mode => :to}}
  end
  def closed(:step, %State{floor: _floor, goal: [{_, _}|_]} = state) do
    {:next_state, :moving, %{state | :status => :moving}}
  end
  def closed(:step, %State{floor: floor, goal: []} = state) do
    {:next_state, :closed, state}
  end
  # Open them if closed and open is requested
  def closed(:open, state) do
    Logger.debug "Opening doors for #{state.id} on floor #{state.floor}"
    {:next_state, :open, %{state | :status => :open}}
  end
  # Ignore repeat close requests
  def closed(:closed, state) do
    {:next_state, :closed, state}
  end
  # If someone requests a pickup from the current floor, open the doors
  def closed({:pickup, from, from}, state) do
    Logger.debug "Opening doors for #{state.id} for pickup on floor #{state.floor}"
    {:next_state, :open, %{state | :status => :open}}
  end
  # If someone requests a pickup from another floor, begin moving
  def closed({:pickup, from, to}, %State{goal: old_goal} = state) do
    Logger.debug "Elevator #{state.id} is starting to move towards pickup on floor #{from}"
    #direction = get_direction(from, to)
    with_goal = %{state | :goal => old_goal ++ [{from, to}]}
    {:next_state, :closed, with_goal}
  end
  # Any other request is invalid in this context
  def closed(other, state) do
    Logger.error "Unexpected transition from :closed -> #{other}"
    {:stop, {:unexpected_transition, :closed, other}, state}
  end
  def closed(:get_status, _, %State{floor: floor, mode: :from, goal: [{from, _}|_], status: status} = state) do
    {:reply, {status, floor, from}, :closed, state}
  end
  def closed(:get_status, _, %State{floor: floor, mode: :to, goal: [{_, to}|_], status: status} = state) do
    {:reply, {status, floor, to}, :closed, state}
  end
  def closed(:get_status, _, %State{floor: floor, goal: [], status: status} = state) do
    {:reply, {status, floor, floor}, :closed, state}
  end

  # Close the doors if open
  def open(:closed, state) do
    Logger.debug "Closing doors for #{state.id} on floor #{state.floor}"
    {:next_state, :closed, %{state | :status => :closed}}
  end
  # If someone requests a pickup from the current floor, open the doors
  def open({:pickup, from, from}, state) do
    Logger.debug "Loading passenger on #{state.id} from floor #{state.floor}"
    {:next_state, :open, state}
  end
  def open({:pickup, from, to}, %State{goal: old_goal} = state) do
    Logger.debug "Closing doors on #{state.id} to begin moving"
    #direction = get_direction(from, to)
    with_goal = %{state | :status => :closed, :goal => old_goal ++ [{from, to}]}
    {:next_state, :closed, with_goal}
  end
  def open(:step, state) do
    Logger.debug "Closing doors on #{state.id}"
    {:next_state, :closed, %{state | :status => :closed}}
  end
  # Any other request is invalid in this context
  def open(other, state) do
    Logger.error "Unexpected transition from :open -> #{other}"
    {:stop, {:unexpected_transition, :open, other}, state}
  end
  def open(:get_status, _, %State{floor: floor, mode: :from, goal: [{from, _}|_], status: status} = state) do
    {:reply, {status, floor, from}, :open, state}
  end
  def open(:get_status, _, %State{floor: floor, mode: :to, goal: [{_, to}|_], status: status} = state) do
    {:reply, {status, floor, to}, :open, state}
  end
  def open(:get_status, _, %State{floor: floor, goal: [], status: status} = state) do
    {:reply, {status, floor, floor}, :open, state}
  end

  def moving(:step, %State{floor: floor, mode: :to, goal: [{_, to}|_] = goal} = state) do
    approaching_floor = get_next_floor(floor, state.mode, goal)
    cond do
      to == approaching_floor ->
        {:next_state, :approaching, %{state | :status => :approaching, :floor => approaching_floor}}
      :else ->
        Logger.debug "Elevator #{state.id} is passing floor #{approaching_floor}"
        {:next_state, :moving, %{state | :floor => approaching_floor}}
    end
  end
  def moving(:step, %State{floor: floor, mode: :from, goal: [{from, _}|_] = goal} = state) do
    approaching_floor = get_next_floor(floor, state.mode, goal)
    cond do
      from == approaching_floor ->
        {:next_state, :approaching, %{state | :status => :approaching, :floor => approaching_floor}}
      :else ->
        Logger.debug "Elevator #{state.id} is passing floor #{approaching_floor}"
        {:next_state, :moving, %{state | :floor => approaching_floor}}
    end
  end
  # Ignore requests for the same floor
  def moving({:pickup, from, from}, state) do
    {:next_state, :moving, state}
  end
  # If someone requests a pickup from another floor, add it to the queue
  def moving({:pickup, from, to}, %State{goal: old_goal} = state) do
    Logger.debug "Received request for pickup from floor #{from} to floor #{to}"
    #direction = get_direction(from, to)
    with_goal = %{state | :goal => old_goal ++ [{from, to}]}
    {:next_state, :moving, with_goal}
  end
  def moving(other, state) do
    {:stop, {:unexpected_transition, :moving, other}, state}
  end
  def moving(:get_status, _, %State{floor: floor, mode: :from, goal: [{from,_}|_], status: status} = state) do
    {:reply, {status, floor, from}, :moving, state}
  end
  def moving(:get_status, _, %State{floor: floor, mode: :to, goal: [{_,to}|_], status: status} = state) do
    {:reply, {status, floor, to}, :moving, state}
  end

  def approaching(:step, %State{floor: floor, mode: :from, goal: [{floor, _}|_]} = state) do
    Logger.debug "Elevator #{state.id} is approaching it's destination floor of #{floor}"
    {:next_state, :arrived, %{state | :status => :arrived}}
  end
  def approaching(:step, %State{floor: floor, mode: :to, goal: [{_, floor}|_]} = state) do
    Logger.debug "Elevator #{state.id} is approaching it's destination floor of #{floor}"
    {:next_state, :arrived, %{state | :status => :arrived}}
  end
  # Ignore requests for the same floor
  def approaching({:pickup, from, from}, state) do
    {:next_state, :approaching, state}
  end
  # If someone requests a pickup from another floor, add it to the queue
  def approaching({:pickup, from, to}, %State{goal: old_goal} = state) do
    Logger.debug "Received request for pickup from floor #{from} to floor #{to}"
    #direction = get_direction(from, to)
    with_goal = %{state | :goal => old_goal ++ [{from, to}]}
    {:next_state, :approaching, with_goal}
  end
  def approaching(other, state) do
    Logger.error "Unexpected transition from :approaching -> #{other}"
    {:stop, {:unexpected_transition, :approaching, other}, state}
  end
  def approaching(:get_status, _, %State{floor: floor, mode: :from, goal: [{from,_}|_], status: status} = state) do
    {:reply, {status, floor, from}, :approaching, state}
  end
  def approaching(:get_status, _, %State{floor: floor, mode: :to, goal: [{_,to}|_], status: status} = state) do
    {:reply, {status, floor, to}, :approaching, state}
  end

  def arrived(:step, %State{floor: floor, mode: :from, goal: [{floor, _}|_] = goal} = state) do
    Logger.debug "Elevator #{state.id} has arrived on floor #{floor} for a pickup, and is opening it's doors"
    {:next_state, :open, %{state | :status => :open, :mode => :to, :goal => goal}}
  end
  def arrived(:step, %State{floor: floor, mode: :to, goal: [{_, floor}|rest] = goal} = state) do
    Logger.debug "Elevator #{state.id} has arrived on floor #{floor} for a dropoff, and is opening it's doors"
    {:next_state, :open, %{state | :status => :open, :mode => :from, :goal => rest}}
  end
  # Ignore requests for the same floor
  def arrived({:pickup, from, from}, state) do
    {:next_state, :arrived, state}
  end
  # If someone requests a pickup from another floor, add it to the queue
  def arrived({:pickup, from, to}, %State{goal: old_goal} = state) do
    Logger.debug "Received request for pickup from floor #{from} to floor #{to}"
    #direction = get_direction(from, to)
    with_goal = %{state | :goal => old_goal ++ [{from, to}]}
    {:next_state, :arrived, with_goal}
  end
  def arrived(other, state) do
    Logger.error "Unexpected transition from :arrived -> #{other}"
    {:stop, {:unexpected_transition, :arrived, other, state}, state}
  end
  def arrived(:get_status, _, %State{floor: floor, mode: :from, goal: [{from,_}|_], status: status} = state) do
    {:reply, {status, floor, from}, :arrived, state}
  end
  def arrived(:get_status, _, %State{floor: floor, mode: :to, goal: [{_,to}|_], status: status} = state) do
    {:reply, {status, floor, to}, :arrived, state}
  end
  def arrived(:get_status, _, %State{floor: floor, goal: [], status: status} = state) do
    {:reply, {status, floor, floor}, :arrived, state}
  end

  # No sync events defined.
  def handle_sync_event(_event, _from, state_name, state) do
    {:reply, :ok, state_name, state}
  end

  # No all_state_events should be sent.
  def handle_event(event, state_name, state) do
    {:stop, {:unknown_event, event, state_name, state}}
  end

  # No info expected.
  def handle_info(_msg, state_name, state) do
    {:next_state, state_name, state}
  end

  # terminate has nothing to clean up.
  def terminate(_reason, _state_name, _state) do
    :ok
  end

  # Code change is a no-op (no previous version exists).
  def code_change(_old_vsn, state, data, _extra) do
    {:ok, state, data}
  end

  defp get_direction(from, to) when from < to,  do: 1
  defp get_direction(from, to) when to < from,  do: -1
  defp get_direction(from, to) when to == from, do: 0

  defp get_next_floor(floor, :from, [{from, _}|_]) when from < floor, do: floor - 1
  defp get_next_floor(floor, :from, [{from, _}|_]) when from > floor, do: floor + 1
  defp get_next_floor(floor, :to, [{_, to}|_]) when to < floor,       do: floor - 1
  defp get_next_floor(floor, :to, [{_, to}|_]) when to > floor,       do: floor + 1
  defp get_next_floor(floor, :from, [{floor, _}|_]),                  do: floor
  defp get_next_floor(floor, :from, []),                              do: floor
  defp get_next_floor(floor, :to, [{_, floor}|_]),                    do: floor
  defp get_next_floor(floor, :to, []),                                do: floor

  defp get_current_goal_floor(_, [{goal_floor, _} | _]), do: goal_floor
  defp get_current_goal_floor(floor, []),                do: floor

end
