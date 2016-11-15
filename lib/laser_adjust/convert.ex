defmodule LaserAdjust.Convert do
  @module_doc """
  Conversion functions
  """

  @doc """
  convert inch to milimeter

  ## Example
  iex> LaserAdjust.Convert.inch_to_mm(0.0)
  0
  iex> LaserAdjust.Convert.inch_to_mm(10.0)
  254
  """
  def inch_to_mm(val), do: val * 25.4 |> round

  @doc """
  convert milimeter to inch
  iex> LaserAdjust.Convert.mm_to_inch(0)
  0.0
  iex> LaserAdjust.Convert.mm_to_inch(254)
  10.0
  """
  def mm_to_inch(val), do: val / 25.4

  @doc """
  ## Example
  iex> LaserAdjust.Convert.listmap_map([%{v: 10.0}, %{v: 15.0}, %{v: 25.0}], :v, &(LaserAdjust.Convert.inch_to_mm(&1)))
  [%{v: 254}, %{v: 381}, %{v: 635}]
  iex> LaserAdjust.Convert.listmap_map([%{v: 254}, %{v: 381}, %{v: 635}], :v, &(LaserAdjust.Convert.mm_to_inch(&1)))
  [%{v: 10.0}, %{v: 15.0}, %{v: 25.0}]
  """
  def listmap_map([], _field, _f), do: []
  def listmap_map(data, field, f) when is_list(data) do
    data |> Enum.map(fn (rec) -> rec |> Map.update!(field, f)end)
  end

end
