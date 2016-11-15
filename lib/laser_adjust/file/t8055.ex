defmodule LaserAdjust.File.T8055 do
  @module_doc """
  Type specific module for 8055 type CNC machine files
  """

  @doc """
  load table -- loads an 8055 type compensation table

  ## Example

  iex> LaserAdjust.File.T8055.load_table("test/data/ALX", "X")
  %{axis: "X", type: :"8055",
    table: %{ 1 => %{err: 0.0, n_err: 0.0, pos: 0.0},
     2 => %{err: -0.00127, n_err: 0.0, pos: 5.0},
     3 => %{err: -0.00276, n_err: 0.0, pos: 10.0}}}
  """
  def load_table(path, axis) do
    data = File.read!(path)
    |> String.split("\n")
    |> Enum.take_while(&(not Regex.match?(~r/^\s*$/, &1)))
    %{ axis: axis, type: :"8055", table: parse_table( data, axis) }
  end

  @doc """
  parse_table -- parse a list of strings representing a compensation table.

  raises an exception if the axis doesn't match

  ## Example

  iex> LaserAdjust.File.T8055.parse_table(
  ...> ["      P001          X    0.00000       EX    0.00000        EX    0.00000",
  ...>  "      P002          X    5.00000       EX   -0.00127        EX    0.00000",
  ...>  "      P003          X   10.00000       EX   -0.00276        EX    0.00000"],
  ...> "X")
  %{1 => %{err: 0.0, n_err: 0.0, pos: 0.0},
    2 => %{err: -0.00127, n_err: 0.0, pos: 5.0},
    3 => %{err: -0.00276, n_err: 0.0, pos: 10.0}}
  """
  def parse_table(data, axis) do
    re = ~r/\s*P(?<index>\d+)\s+(?<axis>[A-Z])\s+(?<loc>[\-\.\d]+\d)\s+E(?<axis2>[A-Z])\s+(?<comp>[\-\.\d]+\d)\s+E(?<axis3>[A-Z])\s+(?<n_comp>[\-\.\d]+\d)/
    
    for line <- data, into: %{} do
      Regex.named_captures(re, line)
      |> fn (match) ->
          %{"axis" => ^axis, "axis2" => ^axis, "axis3" => ^axis,
            "comp" => c, "n_comp" => n, "index" => i, "loc" => l} = match
          { String.to_integer(i),
            %{err: String.to_float(c), n_err: String.to_float(n), pos: String.to_float(l)} }
      end.()
    end
    |> Enum.into(%{})
  end
end
