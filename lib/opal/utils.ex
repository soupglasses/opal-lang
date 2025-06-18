defmodule Opal.Utils do
  def camelize(str) do
    str
    |> String.split(~r{[\s._]+}, trim: true)
    |> Enum.map(&String.capitalize/1)
    |> Enum.join("")
  end

  # Takes a path, and creates a standardized module name.
  def moduleize(path) do
    path
    |> Path.rootname(".opal")
    |> String.split(~r{[\\\/]+}, trim: true)
    |> Enum.map(&camelize/1)
    |> Enum.join(".")
  end
end
