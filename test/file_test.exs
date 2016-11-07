defmodule LaserAdjust.File_Test do
  use ExUnit.Case
  doctest LaserAdjust.File

  import LaserAdjust.File

  test "filter file list" do
    files = ["ALV", "ALV.out", "V Axis Forward.pos"]
    result = [%{axis: "V", file: "ALV", laser: "V Axis Forward.pos", type: :"8055"}]
    assert files |> filter == result

    files = ["ALV", "ALX", "ALX.out", "ALY", "ALY.out", "ALZ", "X Axis Forward.pos",
             "Y Axis Forward.pos"]
    result = [%{axis: "X", file: "ALX", laser: "X Axis Forward.pos", type: :"8055"},
              %{axis: "Y", file: "ALY", laser: "Y Axis Forward.pos", type: :"8055"}]
    assert files |> filter == result

    files = ["X Axis Forward.pos", "X.mp", "X.mp.out", "Y Axis Forward.pos", "Y.mp",
             "Y.mp.out"]
    result = [%{axis: "X", file: "X.mp", laser: "X Axis Forward.pos", type: :"8065"},
              %{axis: "Y", file: "Y.mp", laser: "Y Axis Forward.pos", type: :"8065"}]
    assert files |> filter == result
  end
end
