defmodule Elevators.Elevator do
  @behaviour :gen_fsm
  alias Elevators.Elevator.State

  defmodule State do
    defstruct floor: 1, goal: []
  end

  def start_link() do
    :gen_fsm.start_link(__MODULE__, [], [])
  end

  def init(_) do
    {:ok, :ready, %State{}}
  end

  def ready(:get_status, _, %State{floor: floor, goal: goal} = state) do
    goal_floor = get_current_goal_floor(floor, goal)
    {:reply, {floor, goal_floor}, :ready, state}
  end

  def ready(:step, %State{floor: floor, goal: goal} = state) do
    goal_floor     = get_current_goal_floor(floor, goal)
    with_new_floor = %{state | :floor => get_next_floor(floor, goal_floor)}
    current_floor  = with_new_floor.floor

    with_new_goal = cond do
      goal_floor == current_floor ->
        %{with_new_floor | :goal => get_next_goal_floor(with_new_floor.floor, with_new_floor.goal)}
      true ->
        with_new_floor
    end

    {:next_state, :ready, with_new_goal}
  end

  def ready({:update, floor, goal}, _state) do
    {:next_state, :ready, %State{floor: floor, goal: [{goal, 0}]}}
  end

  # If someone requests a pickup from the current floor, ignore it
  def ready({:pickup, from, from}, state) do
    {:next_state, :ready, state}
  end
  def ready({:pickup, from, to}, %State{goal: old_goal} = state) do
    direction = get_direction(from, to)
    with_goal = %{state | :goal => old_goal ++ [{from, direction}]}
    {:next_state, :ready, with_goal}
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

  defp get_next_floor(floor, goal) when goal < floor, do: floor - 1
  defp get_next_floor(floor, goal) when goal > floor, do: floor + 1
  defp get_next_floor(floor, floor),                  do: floor

  defp get_next_goal_floor(floor, []),   do: [{floor,0}]
  defp get_next_goal_floor(_, [{g, d}]), do: [{g,d}]
  defp get_next_goal_floor(_, [_ | r]),  do: r

  defp get_current_goal_floor(_, [{goal_floor, _} | _]), do: goal_floor
  defp get_current_goal_floor(floor, []),                do: floor

end
