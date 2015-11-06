defmodule Elevators.Mixfile do
  use Mix.Project

  def project do
    [ app: :elevators,
      version: "0.0.1",
      deps: deps ]
  end

  def application do
    [mod: { Elevators.App, [] }]
  end

  defp deps do
    []
  end
end
