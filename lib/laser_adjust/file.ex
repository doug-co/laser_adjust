defmodule LaserAdjust.File do

  @module_doc """
  General Laser File functions, used to find both laser and cnc compensation files.
  """

  import LaserAdjust.File.Type

  @doc """
  return a filtered list of acceptable files to process

  ## Examples
  iex> LaserAdjust.File.filter_accept(nil)
  nil
  iex> LaserAdjust.File.filter_accept(%{ "file" => "ALX", "axis1" => "X", "type1" => "AL" })
  %{ file: "ALX", axis: "X", type: :"8055" }
  iex> LaserAdjust.File.filter_accept(%{ "file" => "Y.mp", "axis2" => "Y", "type2" => "mp" })
  %{ file: "Y.mp", axis: "Y", type: :"8065" }
  iex> LaserAdjust.File.filter_accept(%{ "file" => "X.pos", "axis2" => "X", "type2" => "pos" })
  %{ file: "X.pos", axis: "X", type: :laser }
  """
  def filter_accept(file) when file == nil, do: nil
  def filter_accept(rec = %{ "axis1" => a, "type1" => t }) when a != "" and t != "" do
    %{ file: rec["file"], axis: a, type: file_type(t) }
  end
  def filter_accept(rec = %{ "axis2" => a, "type2" => t }) when a != "" and t != "" do
    %{ file: rec["file"], axis: a, type: file_type(t) }
  end

  @doc """
  return a list of files reduced to axis pairs (laser adjustment file "pos", and 
  compensation file "AL" or "mp")
  """
  def filter_reduce([]), do: [] 
  def filter_reduce([ a = %{ :axis => a1 } | [ b = %{ :axis => a2 } | t] ]) when a1 == a2 do
    file = if compensation?(a[:type]) do
      %{ :file => a[:file], :type => a[:type] }
    else
      nil
    end
    laser = if adjustment?(b[:type]), do: b[:file], else: nil
    if file == nil or laser == nil do
      [ filter_reduce(t) ]
    else
      h = %{ :axis => a[:axis], :file => file[:file], :type => file[:type], :laser => laser }
      [ h | filter_reduce(t) ]
    end
  end
  def filter_reduce([ _h | t ]), do: filter_reduce(t)

  @doc """
  given a path, get a list of files and returns a list of compensation and adjustment
  file pairs with their type for processing.
  """
  def filter(file_list) do
    file_list
    |> Enum.map(fn file ->
      re = ~r/^(?<file>(?<type1>AL)(?<axis1>[A-Z])|(?<axis2>[A-Z]).*\.(?<type2>mp|pos))$/
      Regex.named_captures(re, file)
      |> filter_accept
    end)
    |> Enum.filter(&(&1 != nil))
    |> Enum.sort(&((&1[:axis]<>to_string(&1[:type])) <= (&2[:axis]<>to_string(&2[:type]))))
    |> filter_reduce
  end
end
