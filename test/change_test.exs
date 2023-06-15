defmodule PieceTable.ChangeTest do
  use ExUnit.Case
  doctest PieceTable.Change

  alias PieceTable.Change

  describe "new/3" do
    test "works" do
      assert {:ok, %Change{change: :ins, text: "ciao", position: 4}} = Change.new(:ins, "ciao", 4)
    end

    test "fails with wrong args" do
      assert {:error, "Wrong arguments"} = Change.new(:nope, "ciao", 4)
      assert {:error, "Wrong arguments"} = Change.new(:ins, 13, 4)
      assert {:error, "Wrong arguments"} = Change.new(:ins, "ciao", "ih")
      assert {:error, "Wrong arguments"} = Change.new(:ins, "ciao", -1)
    end
  end

  describe "new!/3" do
    test "works" do
      assert %Change{change: :ins, text: "ciao", position: 4} = Change.new!(:ins, "ciao", 4)
    end

    test "fails with wrong args" do
      assert_raise ArgumentError, fn -> Change.new!(:nope, "ciao", 4) end
      assert_raise ArgumentError, fn -> Change.new!(:ins, 13, 4) end
      assert_raise ArgumentError, fn -> Change.new!(:ins, "ciao", "ih") end
      assert_raise ArgumentError, fn -> Change.new!(:ins, "ciao", -1) end
    end
  end

  describe "invert/1" do
    test "works" do
      change = Change.new!(:ins, "ciao", 4)
      assert {:ok, %Change{change: :del, text: "ciao", position: 4}} = Change.invert(change)
      assert {:ok, ^change} = change |> Change.invert!() |> Change.invert()
    end

    test "fails with wrong args" do
      assert {:error, "Wrong argument"} = Change.invert(%{change: :del, text: "", pos: 0})
    end
  end

  describe "invert!/1" do
    test "works" do
      change = Change.new!(:ins, "ciao", 4)
      assert %Change{change: :del, text: "ciao", position: 4} = Change.invert!(change)
      assert ^change = change |> Change.invert!() |> Change.invert!()
    end

    test "fails with wrong args" do
      assert_raise ArgumentError, fn -> Change.invert!(%{change: :del, text: "", pos: 0}) end
    end
  end
end
