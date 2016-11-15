defmodule LaserAdjust.Convert_Test do
  use ExUnit.Case
  doctest LaserAdjust.Convert

  import LaserAdjust.Convert

  test "inch to mm" do
    assert inch_to_mm(0) == 0
    assert inch_to_mm(0.0) == 0
    assert inch_to_mm(10) == 254
    assert inch_to_mm(25) == 635
  end

  test "mm to inch" do
    assert mm_to_inch(0) == 0.0
    assert mm_to_inch(0.0) == 0.0
    assert mm_to_inch(254) == 10.0
    assert mm_to_inch(635) == 25.0
  end

  test "list.map of map" do
    result = [%{v: 0}, %{v: 254}, %{v: 635}]

    list = []
    assert listmap_map(list, :v, &inch_to_mm/1) == []
    
    list = [%{v: 0}, %{v: 10}, %{v: 25}]
    assert listmap_map(list, :v, &inch_to_mm/1) == result

    list = [%{v: 0.0}, %{v: 10.0}, %{v: 25.0}]
    assert listmap_map(list, :v, &inch_to_mm/1) == result
  end
  
end
