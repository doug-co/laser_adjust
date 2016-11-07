defmodule LaserAdjust.File.Type do

  @module_doc """
  Laser File Type functions, used to map extensions to file type atom, and also
  determine the function of a file { adjustment | compensation }

  A _compensation_ file is a file used by a CNC machine to compensate for error in an 
  axis motion

  An _adjustment_ file is a file created by a laser level to indicate adjustments which
  need to be made to the _compensation_ file.

  The @file_type_map defined below is a data structure which associates a file extension
  with a type and compensation function (the true/false value)  each maping in the
  structure should have the following form:

    extension => { file_type_atom, true if compensation_file else false }

  """

  @file_type_map %{ "pos" => { :laser, false },
                    "AL"  => { :"8055", true },
                    "mp"  => { :"8065", true } }

  @doc """
  given a file extension, return a file type identifier

  iex> LaserAdjust.File.Type.file_type("pos")
  :laser
  iex> LaserAdjust.File.Type.file_type("AL")
  :"8055"
  iex> LaserAdjust.File.Type.file_type("mp")
  :"8065"
  """
  def file_type(ext), do: @file_type_map[ext] |> elem(0) 

  
  @doc """
  returns true if this is a compensation file, false for any other

  # Examples
  iex> LaserAdjust.File.Type.compensation?(:laser)
  false
  iex> LaserAdjust.File.Type.compensation?(:"8055")
  true
  iex> LaserAdjust.File.Type.compensation?(:"8065")
  true
  """
  def compensation?(f_type) do
    Enum.map(Map.keys(@file_type_map),
      fn type -> {@file_type_map[type] |> elem(0), @file_type_map[type] |> elem(1)} end
    )
    |> Enum.into(%{})
    |> Map.fetch(f_type)
    |> elem(1)
  end

  @doc """
  returns true if this is a laser adjustment file type

  ## Examples
  iex> LaserAdjust.File.Type.adjustment?(:laser)
  true
  iex> LaserAdjust.File.Type.adjustment?(:"8055")
  false
  iex> LaserAdjust.File.Type.adjustment?(:"8065")
  false
  """
  def adjustment?(f_type), do: not compensation?(f_type)
    
end
