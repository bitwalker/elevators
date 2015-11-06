defmodule ElevatorsTest do
  use ExUnit.Case
  alias Elevators.Status

  test "adding an elevator creates a pid" do
    {:ok, id} = Elevators.create(1)

    assert(is_integer(id))
  end

  test "new elevators have a state" do
    Elevators.create(2)
    {:ok, actual_state} = Elevators.get_status(2)

    assert %Status{id: 2, floor: 1, goal: 1} = actual_state
  end

  test "nothing happens on step for new elevator" do
    Elevators.create(3)
    Elevators.step(3)
    {:ok, actual_state} = Elevators.get_status(3)

    assert %Status{id: 3, floor: 1, goal: 1} = actual_state
  end

  test "an elevator state can be manually set" do
    Elevators.create(4)
    Elevators.update(4, 5, 5, 5)
    {:ok, actual_state} = Elevators.get_status(5)

    assert %Status{id: 5, floor: 5, goal: 5} = actual_state
  end

  test "an elevator state changes after pickup" do
    Elevators.create(6)

    :ok = Elevators.pickup(6, 3, 1)

    Elevators.step(6)
    assert {:ok, %Status{id: 6, floor: 2, goal: 3}} = Elevators.get_status(6)

    Elevators.step(6)
    assert {:ok, %Status{id: 6, floor: 3, goal: 3}} = Elevators.get_status(6)

    Elevators.step(6)
    assert {:ok, %Status{id: 6, floor: 3, goal: 3}} = Elevators.get_status(6)

  end

  test "an elevator state changes after multiple pickups" do
    Elevators.create(7)
    assert {:ok, %Status{id: 7, floor: 1, goal: 1}} = Elevators.get_status(7)

    :ok = Elevators.pickup(7, 3, 4)
    :ok = Elevators.pickup(7, 2, 1)
    :ok = Elevators.pickup(7, 6, 5)
    :ok = Elevators.pickup(7, 1, 2)

    Elevators.step(7)
    assert {:ok, %Status{id: 7, floor: 2, goal: 3}} = Elevators.get_status(7)

    Elevators.step(7)
    assert {:ok, %Status{id: 7, floor: 3, goal: 2}} = Elevators.get_status(7)

    Elevators.step(7)
    assert {:ok, %Status{id: 7, floor: 2, goal: 6}} = Elevators.get_status(7)

    Elevators.step(7)
    assert {:ok, %Status{id: 7, floor: 3, goal: 6}} = Elevators.get_status(7)

    Elevators.step(7)
    assert {:ok, %Status{id: 7, floor: 4, goal: 6}} = Elevators.get_status(7)

    Elevators.step(7)
    assert {:ok, %Status{id: 7, floor: 5, goal: 6}} = Elevators.get_status(7)

    Elevators.step(7)
    assert {:ok, %Status{id: 7, floor: 6, goal: 1}} = Elevators.get_status(7)

    Elevators.step(7)
    Elevators.step(7)
    Elevators.step(7)
    Elevators.step(7)
    Elevators.step(7)
    assert {:ok, %Status{id: 7, floor: 1, goal: 1}} = Elevators.get_status(7)
  end
end
