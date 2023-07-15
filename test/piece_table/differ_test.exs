defmodule PieceTable.DifferTest do
  use ExUnit.Case
  doctest PieceTable.Differ

  alias PieceTable.Differ

  describe "diff/2" do
    test "works with 2 strings" do
      original = "nel mezo del camino di notra vit"
      result = "nel mezzo del cammin di nostra vita"

      assert {:ok, %PieceTable{original: ^original, result: ^result}} =
               Differ.diff(original, result)
    end

    test "works with PieceTable and string" do
      original_str = "nel mezo del camino di notra vit"
      original = PieceTable.new!(original_str)
      result = "nel mezzo del cammin di nostra vita"

      assert {:ok, %PieceTable{original: ^original_str, result: ^result}} =
               Differ.diff(original, result)
    end

    test "works when changes at the beginning" do
      original = "nel mezo del camino di notra vit"
      result = "del mezzo del cammin di nostra vita"

      assert {:ok, %PieceTable{original: ^original, result: ^result}} =
               Differ.diff(original, result)
    end

    test "works when changes at the end" do
      original = "nel mezo del camino di notra vit"
      result = original <> "a"

      assert {:ok, %PieceTable{original: ^original, result: ^result}} =
               Differ.diff(original, result)
    end

    test "fails with wrong args" do
      assert {:error, _} = Differ.diff("ciao", 1)
    end
  end

  describe "diff!/2" do
    test "works with 2 strings" do
      original = "nel mezo del camino di notra vit"
      result = "nel mezzo del cammin di nostra vita"

      assert %PieceTable{original: ^original, result: ^result} = Differ.diff!(original, result)
    end

    test "works with PieceTable and string" do
      original_str = "nel mezo del camino di notra vit"
      original = PieceTable.new!(original_str)
      result = "nel mezzo del cammin di nostra vita"

      assert %PieceTable{original: ^original_str, result: ^result} =
               Differ.diff!(original, result)
    end

    test "raise with wrong arguments" do
      assert_raise ArgumentError, fn ->
        Differ.diff!("ciao", 1)
      end
    end
  end
end
