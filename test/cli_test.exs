defmodule LaserAdjust.CLI_Test do
  use ExUnit.Case
  doctest LaserAdjust.CLI

  import LaserAdjust.CLI

  test "--force argument validator" do
    assert force(true) == { :force, true }
    assert force(false) == { :force, false }
    assert_raise(RuntimeError, fn -> force("abc") end)
  end

  test "--quiet argument validator" do
    assert quiet(true) == { :quiet, true }
    assert quiet(false) == { :quiet, false }
    assert_raise(RuntimeError, fn -> quiet("abc") end)
  end

  test "--axis argument validator" do
    List.first('A')..List.first('Z')
    |> Enum.each(fn val -> assert axis(to_string([val])) == { :axis, to_string([val]) } end)
    [ 1, 2.0, true, "abc" ]
    |> Enum.each(fn val -> assert_raise(RuntimeError, fn -> axis(val) end) end)
  end

  test "--type argument validator" do
    ["8055", "8065"]
    |> Enum.each(fn val -> assert type(val) == { :type, val } end)
    [ 1, 2.0, true, "abc" ]
    |> Enum.each(fn val -> assert_raise(RuntimeError, fn -> type(val) end) end)
  end

  test "path validation" do
    assert path([]) == { :path, "." }
    assert path("..") == { :path, ".." }
    assert path("/tmp") == { :path, "/tmp" }
  end

  test "parse arguments" do
    Enum.each([
      { [ "-a", "X" ], %{ path: ".", axis: [ "X" ] } },
      { [ "-t", "8055" ], %{ path: ".", axis: [], type: "8055" } },
      { [ "-a", "X", "-a", "Y" ], %{ path: ".", axis: [ "X", "Y" ] } },
      { [ "-f", "-q" ], %{ path: ".", axis: [], force: true, quiet: true } },
    ],
      fn { args, opts } -> assert LaserAdjust.CLI.parse_args(args) == opts end
    )
  end

  test "build file list" do
    result = [%{axis: "X", file: "ALX", laser: "X Axis Forward.pos", type: :"8055"},
              %{axis: "Y", file: "ALY", laser: "Y Axis Forward.pos", type: :"8055"}]
    assert build_file_list("./example/8055") == result

    result = [%{axis: "X", file: "X.mp", laser: "X Axis Forward.pos", type: :"8065"},
              %{axis: "Y", file: "Y.mp", laser: "Y Axis Forward.pos", type: :"8065"}]
    assert build_file_list("./example/8065") == result
  end

  # test "process with no axis list" do
  #   opts = %{ path: "examples/8055", axis: [] }
  #   files = [ "ALX", "ALY", "X.pos", "Y.pos" ] |> LaserAdjust.File.filter
  #   LaserAdjust.CLI.process(opts, files)

  #   opts = %{ path: "examples/8055", axis: ["X"] }
  #   files = [ "ALX", "ALY", "X.pos", "Y.pos" ] |> LaserAdjust.File.filter
  #   LaserAdjust.CLI.process(opts, files)
    
  # end
end
