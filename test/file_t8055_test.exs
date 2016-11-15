defmodule LaserAdjust.File.T8055_Test do
  use ExUnit.Case
  doctest LaserAdjust.File.T8055

  import LaserAdjust.File.T8055

  test "empty file" do
    assert parse_table([], "X") == %{}
  end

  test "correct data" do
    data = ["      P001          X    0.00000       EX    0.00000        EX    0.00000",
            "      P002          X    5.00000       EX   -0.00127        EX    0.00000",
            "      P003          X   10.00000       EX   -0.00276        EX    0.00000"]
    result = %{1 => %{err: 0.0, n_err: 0.0, pos: 0.0},
               2 => %{err: -0.00127, n_err: 0.0, pos: 5.0},
               3 => %{err: -0.00276, n_err: 0.0, pos: 10.0}}
    assert parse_table(data, "X") == result
  end

  test "incorrect axis" do
    ["      P001          Y    0.00000       EX    0.00000        EX    0.00000",
     "      P001          X    0.00000       EY    0.00000        EX    0.00000",
     "      P001          X    0.00000       EX    0.00000        EY    0.00000",
     "      P001          Y    0.00000       EY    0.00000        EY    0.00000"]
     |> (Enum.each fn (rec) ->
      assert_raise(MatchError, fn -> parse_table([rec], "X") end )
    end)
  end
  
end
