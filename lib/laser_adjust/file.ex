defmodule LaserAdjust.File do

  require Logger
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


  @doc """
  load laser adjustment file

  iex>LaserAdjust.File.load_adjustments("test/data/X Axis Forward.pos")
  %{pre: "API Linear Error Compensation Table\r\nPosition   \tUnidirectional Avg Error\r",
    post: "\r\nAPI Linear Standard Deviation Error Table\r\n",
    table: %{1 => %{err: -5.5e-5, pos: 0.0}, 2 => %{err: -4.7e-5, pos: 5.0},
    3 => %{err: -7.5e-5, pos: 10.0}, 4 => %{err: -5.2e-5, pos: 15.0},
    5 => %{err: 2.0e-6, pos: 20.0}, 6 => %{err: -3.4e-5, pos: 25.0}}}
  """
  def load_adjustments(path) do
    { :ok, data } = File.read(path)
    parse_adjustment(data |> String.split("\n"))
  end

  @doc """
  parse adjustment (laser adjustment file), and return an indexed position/error table

  iex> LaserAdjust.File.parse_adjustment(
  ...> ["blah blah, blah",
  ...>  "Position   	Unidirectional Avg Error",
  ...>  " 0.000000	-0.000055",
  ...>  " 5.000000	-0.000047",
  ...>  "10.000000	-0.000075",
  ...>  "15.000000	-0.000052",
  ...>  ""])
  %{pre: "blah blah, blah\nPosition   	Unidirectional Avg Error", post: "",
    table: %{1 => %{err: -5.5e-5, pos: 0.0}, 2 => %{err: -4.7e-5, pos: 5.0},
      3 => %{err: -7.5e-5, pos: 10.0}, 4 => %{err: -5.2e-5, pos: 15.0}}}
  """
  def parse_adjustment(data, state \\ :start, index \\ 1)
  def parse_adjustment([], _state, _index), do: [ [] | [ %{} | [] ]]
  def parse_adjustment(data, :start, index) do
    [ pre | [ data | post ]] = parse_adjustment(data, :head, index)
    %{ table: data, pre: Enum.join(pre, "\n"), post: Enum.join(post, "\n") }
  end
  def parse_adjustment([ h | t ], :head, index) do
    re = ~r/Position\s+Unidirectional Avg Error/
    next_state = if Regex.match?(re, h), do: :data, else: :head
    [  pre | post ] = parse_adjustment(t, next_state, index)
    [ [ h | pre ] | post ]
  end
  def parse_adjustment(data = [h|t], :data, index ) do
    re = ~r/(?<pos>-?\d+\.\d+)\s+(?<err>-?\d+\.\d*)/
    match = Regex.named_captures(re,h)

    if match != nil do
      %{ "err" => err, "pos" => pos } = match
      [ pre | [ d_list | post ]] = parse_adjustment(t, :data, index + 1)
      data = %{ err: String.to_float(err), pos: String.to_float(pos) }
      d_list = Map.put(d_list, index, data)
      [ pre | [ d_list | post ]]
    else
      [ [] | [%{} | data] ]
    end
  end


  @doc """
  based on file type, run code from module for that file type, in other words,
  use the file type to generate the module name where the load_table function 
  is called.

  iex> LaserAdjust.File.load_compensation("test/data/ALA", "A", :"8055")
  %{axis: "A", type: :"8055",
    table: %{1 => %{err: 0.0, n_err: 0.0, pos: 0.0},
     2 => %{err: -0.00127, n_err: 0.0, pos: 5.0},
     3 => %{err: -0.00276, n_err: 0.0, pos: 10.0},
     4 => %{err: -0.00311, n_err: 0.0, pos: 15.0},
     5 => %{err: -0.00258, n_err: 0.0, pos: 20.0},
     6 => %{err: -2.4e-4, n_err: 0.0, pos: 25.0},
     7 => %{err: 0.00238, n_err: 0.0, pos: 30.0},
     8 => %{err: 0.00395, n_err: 0.0, pos: 35.0},
     9 => %{err: 0.00494, n_err: 0.0, pos: 40.0},
     10 => %{err: 0.00539, n_err: 0.0, pos: 45.0}}}
  iex> LaserAdjust.File.load_compensation("test/data/A.mp", "A", :"8065")
  ...> |> Map.fetch(:table)
  {:ok, %{1 => %{err: -0.0127, n_err: 0.0, pos: -127.0},
    2 => %{err: 0.0, n_err: 0.0, pos: 0.0},
    3 => %{err: 0.0028, n_err: 0.0, pos: 127.0},
    4 => %{err: -0.0328, n_err: 0.0, pos: 254.0},
    5 => %{err: -0.064, n_err: 0.0, pos: 381.0},
    6 => %{err: -0.0828, n_err: 0.0, pos: 508.0},
    7 => %{err: -0.0925, n_err: 0.0, pos: 635.0},
    8 => %{err: -0.1034, n_err: 0.0, pos: 762.0},
    9 => %{err: -0.111, n_err: 0.0, pos: 889.0},
    10 => %{err: -0.1156, n_err: 0.0, pos: 1016.0}}}
  """
  def load_compensation(path, axis, type) do
    Module.concat([ LaserAdjust, File, "T" <> to_string(type) ])
    |> apply(:load_table, [path, axis])
    # use the type to generate a module name to use for loading the file
    
  end
  
  @doc """
  standardize units

  This function converts all units to metric
  parameters:
  data -> list of Maps
  field -> field to use for measurement value
  returns { data, original_unit }

  ## Example

  iex> LaserAdjust.File.standardize_units([%{err: -5.5e-5, pos: 0.0},
  ...>                                     %{err: -7.5e-5, pos: 15.0},
  ...>                                     %{err: -3.4e-5, pos: 115.0},
  ...>                                     %{err: -4.6e-5, pos: 120.0}], :pos)
  {[%{err: -5.5e-5, pos: 0}, %{err: -7.5e-5, pos: 381},
    %{err: -3.4e-5, pos: 2921}, %{err: -4.6e-5, pos: 3048}], :imperial}

  iex> LaserAdjust.File.standardize_units([%{err: -5.5e-5, pos: 0},
  ...>                                     %{err: -7.5e-5, pos: 381},
  ...>                                     %{err: -3.4e-5, pos: 2921},
  ...>                                     %{err: -4.6e-5, pos: 3048}], :pos)
  {[%{err: -5.5e-5, pos: 0}, %{err: -7.5e-5, pos: 381},
    %{err: -3.4e-5, pos: 2921}, %{err: -4.6e-5, pos: 3048}], :metric}
  """
  # if a measurement value is over 1000, it is assumed to be mm instead of inches
  @threshold 1000    
  def standardize_units(data, field) do
    import LaserAdjust.Convert
    Enum.sort(data, &(&1[field] <= &2[field]))
    |> fn (data) ->
      { data, (if List.last(data)[:pos] > @threshold, do: :metric, else: :imperial) } end.()
    |> fn
      ({data, :metric}) -> {data, :metric}
      ({data, :imperial}) -> { listmap_map(data, field, &inch_to_mm/1), :imperial }
    end.()
  end

end
