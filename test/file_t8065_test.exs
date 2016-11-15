defmodule LaserAdjust.File.T8065_Test do
  use ExUnit.Case
  doctest LaserAdjust.File.T8065

  import LaserAdjust.File.T8065

  test "empty parse table" do
    assert parse_table([]) == [ [] | [ %{} | [] ] ]
  end

  test "missing pre and post" do
    data = ["2;/LSCRWDATA/DATA/POSITION 1                        ;-127.0000",
            "2;/LSCRWDATA/DATA/POSITION 2                        ;0.0000",
            "2;/LSCRWDATA/DATA/POSERROR 1                        ;-0.0127",
            "2;/LSCRWDATA/DATA/POSERROR 2                        ;0.0000",
            "2;/LSCRWDATA/DATA/NEGERROR 1                        ;0.0000",
            "2;/LSCRWDATA/DATA/NEGERROR 2                        ;0.0000"]
    result = %{post: "", pre: "",
               table: %{1 => %{err: -0.0127, n_err: 0.0, pos: -127.0},
                        2 => %{err: 0.0, n_err: 0.0, pos: 0.0}}}
    assert parse_table(data) == result
  end

  test "missing post" do
    data = ["2;/LSCRWDATA/REFNEED          ;0",
            "2;/LSCRWDATA/DATA/POSITION 1                        ;-127.0000",
            "2;/LSCRWDATA/DATA/POSITION 2                        ;0.0000",
            "2;/LSCRWDATA/DATA/POSERROR 1                        ;-0.0127",
            "2;/LSCRWDATA/DATA/POSERROR 2                        ;0.0000",
            "2;/LSCRWDATA/DATA/NEGERROR 1                        ;0.0000",
            "2;/LSCRWDATA/DATA/NEGERROR 2                        ;0.0000"]
    result = %{post: "", pre: "2;/LSCRWDATA/REFNEED          ;0",
               table: %{1 => %{err: -0.0127, n_err: 0.0, pos: -127.0},
                        2 => %{err: 0.0, n_err: 0.0, pos: 0.0}}}
    assert parse_table(data) == result
  end

  test "missing pre" do
    data = ["2;/LSCRWDATA/DATA/POSITION 1                        ;-127.0000",
            "2;/LSCRWDATA/DATA/POSITION 2                        ;0.0000",
            "2;/LSCRWDATA/DATA/POSERROR 1                        ;-0.0127",
            "2;/LSCRWDATA/DATA/POSERROR 2                        ;0.0000",
            "2;/LSCRWDATA/DATA/NEGERROR 1                        ;0.0000",
            "2;/LSCRWDATA/DATA/NEGERROR 2                        ;0.0000",
            "2;/FILTER/FILTER 1/ORDER                            ;0"]
    result = %{post: "2;/FILTER/FILTER 1/ORDER                            ;0", pre: "",
               table: %{1 => %{err: -0.0127, n_err: 0.0, pos: -127.0},
                        2 => %{err: 0.0, n_err: 0.0, pos: 0.0}}}
    assert parse_table(data) == result
  end
end
