defmodule LaserAdjust.File.T8065 do
  @module_doc """
  Type specific module for 8065 type CNC machine files
  """

  @doc """
  load table -- loads an 8065 type compensation table

  ## Example
  iex> LaserAdjust.File.T8065.load_table("test/data/X.mp", "X")
  %{axis: "X", post: "2;/FILTER/FILTER 1/ORDER                            ;0\n",
    pre: "﻿X AXIS                        ;3100\nMM                            ;0\n2;/LSCRWDATA/REFNEED          ;0",
    table: %{1 => %{err: -0.0127, n_err: 0.0, pos: -127.0},
    2 => %{err: 0.0, n_err: 0.0, pos: 0.0},
    3 => %{err: 0.0028, n_err: 0.0, pos: 127.0}},
    type: :"8065"}
  """
  def load_table(path, axis) do
    dev = File.open!(path, [ :read, { :encoding, { :utf16, :little } } ])
    data = IO.read(dev, :all)
    |> String.split("\n")
    if Regex.match?(~r/#{axis} AXIS/, List.first(data)) do
      parse_table(data)
    else
      raise "axis '#{axis}' doesn't match axis in file"
    end
    Map.put(parse_table(data), :axis, axis)
    |> Map.put(:type, :"8065")
  end

  @doc """
  iex> LaserAdjust.File.T8065.parse_table(
  ...> ["2;/LSCRWDATA/REFNEED          ;0",
  ...>  "2;/LSCRWDATA/DATA/POSITION 1                        ;-127.0000",
  ...>  "2;/LSCRWDATA/DATA/POSITION 2                        ;0.0000",
  ...>  "2;/LSCRWDATA/DATA/POSITION 3                        ;127.0000",
  ...>  "2;/LSCRWDATA/DATA/POSERROR 1                        ;-0.0127",
  ...>  "2;/LSCRWDATA/DATA/POSERROR 2                        ;0.0000",
  ...>  "2;/LSCRWDATA/DATA/POSERROR 3                        ;0.0028",
  ...>  "2;/LSCRWDATA/DATA/NEGERROR 1                        ;0.0000",
  ...>  "2;/LSCRWDATA/DATA/NEGERROR 2                        ;0.0000",
  ...>  "2;/LSCRWDATA/DATA/NEGERROR 3                        ;0.0000",
  ...>  "2;/FILTER/FILTER 1/ORDER                            ;0"])
  %{post: "2;/FILTER/FILTER 1/ORDER                            ;0",
    pre: "2;/LSCRWDATA/REFNEED          ;0",
    table: %{1 => %{err: -0.0127, n_err: 0.0, pos: -127.0},
      2 => %{err: 0.0, n_err: 0.0, pos: 0.0},
      3 => %{err: 0.0028, n_err: 0.0, pos: 127.0}}}
  """
  def parse_table(data, state \\ :start)
  def parse_table([], _state), do: [ [] | [ %{} | [] ] ] # shouldn't get here normally
  def parse_table(data, :start) do
    re = ~r/LSCRWDATA\/DATA\//
    next_state = if Regex.match?(re, data |> List.first), do: :data, else: :head
    [ pre | [ data | post ]] = parse_table(data, next_state)
    %{ table: data, pre: Enum.join(pre, "\n"), post: Enum.join(post, "\n") }
  end
  def parse_table([h|t], :head) do
    next_state = if Regex.match?(~r/LSCRWDATA\/REFNEED/, h), do: :data, else: :head
    [ pre | post  ] = parse_table(t, next_state)
    [ [ h | pre ] | post ]
  end
  def parse_table(data = [h|t], :data) do
    type_map = %{ "POSITION" => :pos, "POSERROR" => :err, "NEGERROR" => :n_err }
    re = ~r/(?<type>POSITION|POSERROR|NEGERROR) (?<index>\d+)\s+;(?<value>[\-\.\d]+)/
    match = Regex.named_captures(re, h)
    if match != nil do
      %{ "index" => index, "type" => type, "value" => val } = match
      key = type_map[type]
      val = String.to_float(val)
      [ pre | [ d_list | post ]] = parse_table(t, :data)
      d_list = Map.update(d_list, String.to_integer(index), %{key => val}, &(Map.put(&1, key,val)))
      [ pre | [ d_list | post ]]
    else
      [ [] | [ %{} | data ] ]
    end
  end
end
