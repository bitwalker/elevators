defmodule ElevatorsTest do
  use ExUnit.Case
  alias Elevators.Status

  test "nothing happens on step for new elevator" do
    Elevators.create(3)
    Elevators.step(3)
    {:ok, actual_state} = Elevators.get_status(3)

    assert %Status{id: 3, floor: 1, goal: 1} = actual_state
  end

  test "simple run from closed -> called -> arriving -> opening -> closing -> idle" do
    Elevators.create(6)
    assert {:ok, %Status{floor: 1, goal: 1, state: :closed}} = Elevators.get_status(6)
    Elevators.step(6)
    assert {:ok, %Status{floor: 1, goal: 1, state: :closed}} = Elevators.get_status(6)

    :ok = Elevators.pickup(6, 3, 1)
    assert {:ok, %Status{floor: 1, goal: 3, state: :closed}} = Elevators.get_status(6)
    Elevators.step(6)
    assert {:ok, %Status{floor: 1, goal: 3, state: :moving}} = Elevators.get_status(6)

    Elevators.step(6)
    assert {:ok, %Status{floor: 2, goal: 3, state: :moving}} = Elevators.get_status(6)
    Elevators.step(6)
    assert {:ok, %Status{floor: 3, goal: 3, state: :approaching}} = Elevators.get_status(6)

    Elevators.step(6)
    assert {:ok, %Status{floor: 3, goal: 3, state: :arrived}} = Elevators.get_status(6)

    Elevators.step(6)
    assert {:ok, %Status{floor: 3, goal: 1, state: :open}} = Elevators.get_status(6)

    Elevators.step(6)
    assert {:ok, %Status{floor: 3, goal: 1, state: :closed}} = Elevators.get_status(6)
    Elevators.step(6)
    assert {:ok, %Status{floor: 3, goal: 1, state: :moving}} = Elevators.get_status(6)

    Elevators.step(6)
    assert {:ok, %Status{floor: 2, goal: 1, state: :moving}} = Elevators.get_status(6)
    Elevators.step(6)
    assert {:ok, %Status{floor: 1, goal: 1, state: :approaching}} = Elevators.get_status(6)
    Elevators.step(6)
    assert {:ok, %Status{floor: 1, goal: 1, state: :arrived}} = Elevators.get_status(6)

    Elevators.step(6)
    assert {:ok, %Status{floor: 1, goal: 1, state: :open}} = Elevators.get_status(6)
    Elevators.step(6)
    assert {:ok, %Status{floor: 1, goal: 1, state: :closed}} = Elevators.get_status(6)
    Elevators.step(6)
    assert {:ok, %Status{floor: 1, goal: 1, state: :closed}} = Elevators.get_status(6)

  end

  test "complex run with multiple pickups" do
    Elevators.create(7)
    assert {:ok, %Status{floor: 1, goal: 1, state: :closed}} = Elevators.get_status(7)

    :ok = Elevators.pickup(7, 3, 4)
    :ok = Elevators.pickup(7, 2, 1)
    :ok = Elevators.pickup(7, 6, 5)
    :ok = Elevators.pickup(7, 1, 2)

    assert {:ok, %Status{floor: 1, goal: 3, state: :closed}} = Elevators.get_status(7)

    Elevators.step(7)
    assert {:ok, %Status{floor: 1, goal: 3, state: :moving}} = Elevators.get_status(7)

    Elevators.step(7)
    assert {:ok, %Status{floor: 2, goal: 3, state: :moving}} = Elevators.get_status(7)

    Elevators.step(7)
    assert {:ok, %Status{floor: 3, goal: 3, state: :approaching}} = Elevators.get_status(7)
    Elevators.step(7)
    assert {:ok, %Status{floor: 3, goal: 3, state: :arrived}} = Elevators.get_status(7)
    Elevators.step(7)
    assert {:ok, %Status{floor: 3, goal: 4, state: :open}} = Elevators.get_status(7)

    Elevators.step(7)
    assert {:ok, %Status{floor: 3, goal: 4, state: :closed}} = Elevators.get_status(7)
    Elevators.step(7)
    assert {:ok, %Status{floor: 3, goal: 4, state: :moving}} = Elevators.get_status(7)
    Elevators.step(7)
    assert {:ok, %Status{floor: 4, goal: 4, state: :approaching}} = Elevators.get_status(7)
    Elevators.step(7)
    assert {:ok, %Status{floor: 4, goal: 4, state: :arrived}} = Elevators.get_status(7)
    Elevators.step(7)
    assert {:ok, %Status{floor: 4, goal: 2, state: :open}} = Elevators.get_status(7)
    Elevators.step(7)
    assert {:ok, %Status{floor: 4, goal: 2, state: :closed}} = Elevators.get_status(7)
    Elevators.step(7)
    Elevators.step(7)
    Elevators.step(7)
    assert {:ok, %Status{floor: 2, goal: 2, state: :approaching}} = Elevators.get_status(7)
    Elevators.step(7)
    assert {:ok, %Status{floor: 2, goal: 2, state: :arrived}} = Elevators.get_status(7)
    Elevators.step(7)
    assert {:ok, %Status{floor: 2, goal: 1, state: :open}} = Elevators.get_status(7)
    Elevators.step(7)
    assert {:ok, %Status{floor: 2, goal: 1, state: :closed}} = Elevators.get_status(7)

    Elevators.step(7)
    Elevators.step(7)
    assert {:ok, %Status{floor: 1, goal: 1, state: :approaching}} = Elevators.get_status(7)

    Elevators.step(7)
    assert {:ok, %Status{floor: 1, goal: 1, state: :arrived}} = Elevators.get_status(7)

    Elevators.step(7)
    assert {:ok, %Status{floor: 1, goal: 6, state: :open}} = Elevators.get_status(7)

    Elevators.step(7)
    assert {:ok, %Status{floor: 1, goal: 6, state: :closed}} = Elevators.get_status(7)

  end
end
