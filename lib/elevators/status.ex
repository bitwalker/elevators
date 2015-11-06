defmodule Elevators.Status do
  @moduledoc """
  Struct representing elevator status.

    - id    = integer
    - pid   = elevator pid
    - floor = integer (current floor)
    - goal  = [Goal]
  """
  defstruct id: nil, pid: nil, floor: nil, goal: nil
end
