# Elevators

## Usage

Here is a simple example of an elevator receiving a pickup call for floor 3 while on floor 1

```elixir
id = 1
Elevators.create(id)
{:ok, status} = Elevators.get_status(id)
# status = %Status{id: 1, floor: 1, goal: 1}

Elevators.pickup(id, 3, 1)
{:ok, status} = Elevators.get_status(id)
# status = %Status{id: 1, floor: 1, goal: 3}

Elevators.step(id)
{:ok, status} = Elevators.get_status(id)
# status = %Status{id: 1, floor: 2, goal: 3}

Elevators.step(id)
{:ok, status} = Elevators.get_status(id)
# status = %Status{id: 1, floor: 3, goal: 3}
```

Here is a more complex example of a multi-pickup situation, notes inline

```elixir
Elevators.create(7)

# initial state, floor 1, goal 1
assert {:ok, %Status{floor: 1, goal: 1}} = Elevators.get_status(7)

# pickup calls are made for floors 3, 2, 6, and 1 respectively
:ok = Elevators.pickup(7, 3, 4)
:ok = Elevators.pickup(7, 2, 1)
:ok = Elevators.pickup(7, 6, 5)
:ok = Elevators.pickup(7, 1, 2)

# elevator first makes it's way to floor 3
Elevators.step(7)
assert {:ok, %Status{floor: 2, goal: 3}} = Elevators.get_status(7)

# once it gets there, the front of the queue (FIFO) is popped, and the new goal is 2
Elevators.step(7)
assert {:ok, %Status{floor: 3, goal: 2}} = Elevators.get_status(7)

# the person on the 2nd floor wanted to go down, but 6 needs to be picked up first because they requested a pickup
# before the person on the 2nd floor was able to press any buttons. It would be possible to add additional logic to the
# Finite State Machine in order to calculate shortest distances and more efficiently use the people's time by scanning
# the future goals and picking the next goal based on distance rather than a simple FIFO, but that is for another day.

Elevators.step(7)
assert {:ok, %Status{floor: 2, goal: 6}} = Elevators.get_status(7)

Elevators.step(7)
assert {:ok, %Status{floor: 3, goal: 6}} = Elevators.get_status(7)

Elevators.step(7)
assert {:ok, %Status{floor: 4, goal: 6}} = Elevators.get_status(7)

Elevators.step(7)
assert {:ok, %Status{floor: 5, goal: 6}} = Elevators.get_status(7)

Elevators.step(7)
assert {:ok, %Status{floor: 6, goal: 1}} = Elevators.get_status(7)

Elevators.step(7) # 5
Elevators.step(7) # 4
Elevators.step(7) # 3
Elevators.step(7) # 2
Elevators.step(7) # 1
assert {:ok, %Status{floor: 1, goal: 1}} = Elevators.get_status(7)
```
