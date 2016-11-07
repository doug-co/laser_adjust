defmodule LaserAdjust.CLI do

  @module_doc """
  """

  def main(argv) do
    options = argv
    |> parse_args
    |> IO.inspect

    { :ok, file_list } = File.ls(options[:path])
    |> LaserAdjust.File.filter
    |> IO.inspect
    
    process(options, file_list)
  end

  @doc """
  """

  def parse_args(argv) do
    [ opts | [ path | _ ]] = OptionParser.parse(argv, 
      switches: [axis: [:string, :keep], type: :string, force: :boolean, quiet: :boolean,
                 verbose: :count, help: :boolean],
      aliases: [a: :axis, t: :type, f: :force, q: :quiet, v: :verbose, h: :help])
      |> Tuple.to_list

    # verify options and consolidate them in a useable form
    verified_opts = opts
    |> Enum.map(fn { k, v } -> apply(LaserAdjust.CLI, k, [v]) end )
    |> collect_axis
    
    Enum.into([ path(path) | verified_opts ], %{})
  end

  @doc """
  build a filtered file list, this will search the path for valid files to process and
  associate adjustment and compensation files based on their axis.
  """
  def build_file_list(path) do
    { :ok, file_list } = File.ls(path)
    file_list |> LaserAdjust.File.filter
  end

  @doc """
  Options allow for multiple axis, collect_axis, combines all of the axis
  arguments into a single list assigned to axis:

  ## Examples
  iex> LaserAdjust.CLI.collect_axis([ axis: "A", type: "8055", force: true, axis: "B" ])
  [ axis: [ "A", "B" ], type: "8055", force: true ]
  """
  def collect_axis(list) do
    { opts, axis: axis_vals } = _collect_axis(list)
    [ { :axis, axis_vals } | opts ]
  end
  defp _collect_axis([]), do: { [], axis: [] }
  defp _collect_axis([{ :axis , v } | t ]) do
    { opts, axis: axis_vals } = _collect_axis(t)
    { opts, axis: [ v | axis_vals ] }
  end
  defp _collect_axis([ h | t ]) do
    { opts, axis } = _collect_axis(t)
    { [ h | opts ], axis }
  end

  
  def help(true) do
    IO.puts """
    usage: laser_adjust [--quiet|-q] [--force|-f] [--axis|-a {axis-name A-Z}] [--type|-t {8055|8065}] path
    """
    System.halt(0)
  end

  @doc """
  returns a force option tuple with a valid value

  ## Examples
  iex> LaserAdjust.CLI.force(true)
  {:force, true}
  iex> LaserAdjust.CLI.force(false)
  {:force, false}
  """
  def force(true), do: { :force, true }
  def force(false), do: { :force, false }
  def force(val), do: raise "expecting boolean, got '#{val}'"

  @doc """
  returns a quiet option tuple with a valid value

  ## Examples
  iex> LaserAdjust.CLI.quiet(true)
  {:quiet, true}
  iex> LaserAdjust.CLI.quiet(false)
  {:quiet, false}
  """
  def quiet(true), do: { :quiet, true }
  def quiet(false), do: { :quiet, false }
  def quiet(val), do: raise "expecting boolean, got '#{val}'"

  @doc """
  returns an axis option tuple with a valid value

  ## Examples
  iex> LaserAdjust.CLI.axis("A")
  {:axis, "A"}
  iex> LaserAdjust.CLI.axis("X")
  {:axis, "X"}
  """
  def axis(value) do
    if Regex.match?(~r/^[A-Z]$/, to_string(value)) do
      {:axis, to_string(value) }
    else
      raise "invalid axis value: '#{value}'"
    end
  end

  @doc """
  returns a type option tuple with a valid value

  ## Examples
  iex> LaserAdjust.CLI.type("8055")
  {:type, "8055"}
  iex> LaserAdjust.CLI.type("8065")
  {:type, "8065"}
  """
  def type(value) do
    if Regex.match?(~r/^(8055|8065)$/, to_string(value)) do
      {:type, to_string(value) }
    else
      raise "invalid type value: '#{value}'"
    end
  end

  def path([]), do: { :path, "." }
  def path(value) do
    if File.dir?(value) do
      { :path, value }
    else
      raise "path '#{value}' not found"
    end
  end

  @doc """
  
  """
  def process(opts = %{ axis: axis_list }, files) when axis_list == [] do
    process(Enum.into([ axis: Enum.map(files, &(&1[:axis]))], opts), files)
  end
  def process(opts, files) do
    IO.puts "Process B:"
#    IO.inspect opts
#    IO.inspect files

    selected_axis = opts[:axis]
    |> Enum.map(&({&1, true}))
    |> Enum.into(%{})

    files
    |> Enum.filter(&(selected_axis[&1[:axis]]))
    |> IO.inspect
    |> Enum.each(&(process_axis(&1)))
  end

  def process_axis(axis) do
    IO.puts "Process Axis:"
    axis |> IO.inspect
  end
end

#LaserAdjust.CLI.main(["-a", "X", "-q", "-a", "Y", "--no-quiet", "-t", "8055", "-f", "/ab/c"])
