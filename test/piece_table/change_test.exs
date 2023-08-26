defmodule PieceTable.ChangeTest do
  use ExUnit.Case
  doctest PieceTable.Change

  alias PieceTable.Change

  describe "new/3" do
    test "works" do
      assert {:ok, %Change{change: :ins, text: "ciao", position: 4, blame: "bob"}} =
               Change.new(:ins, "ciao", 4, "bob")
    end

    test "fails with wrong args" do
      assert {:error, :wrong_arguments} = Change.new(:nope, "ciao", 4, nil)
      assert {:error, :wrong_arguments} = Change.new(:ins, 13, 4, nil)
      assert {:error, :wrong_arguments} = Change.new(:ins, "ciao", "ih", nil)
      assert {:error, :wrong_arguments} = Change.new(:ins, "ciao", -1, nil)
    end
  end

  describe "new!/3" do
    test "works" do
      assert %Change{change: :ins, text: "ciao", position: 4, blame: "ehi"} =
               Change.new!(:ins, "ciao", 4, "ehi")
    end

    test "fails with wrong args" do
      assert_raise ArgumentError, fn -> Change.new!(:nope, "ciao", 4, nil) end
      assert_raise ArgumentError, fn -> Change.new!(:ins, 13, 4, nil) end
      assert_raise ArgumentError, fn -> Change.new!(:ins, "ciao", "ih", nil) end
      assert_raise ArgumentError, fn -> Change.new!(:ins, "ciao", -1, nil) end
    end
  end

  describe "invert/1" do
    test "works" do
      change = Change.new!(:ins, "ciao", 4, nil)
      assert {:ok, %Change{change: :del, text: "ciao", position: 4, blame: nil}} = Change.invert(change)
      assert {:ok, ^change} = change |> Change.invert!() |> Change.invert()
    end

    test "fails with wrong args" do
      assert {:error, :wrong_argument} = Change.invert(%{change: :del, text: "", pos: 0})
    end
  end

  describe "invert!/1" do
    test "works" do
      change = Change.new!(:ins, "ciao", 4, nil)
      assert %Change{change: :del, text: "ciao", position: 4, blame: nil} = Change.invert!(change)
      assert ^change = change |> Change.invert!() |> Change.invert!()
    end

    test "fails with wrong args" do
      assert_raise ArgumentError, fn ->
        Change.invert!(%{change: :del, text: "", pos: 0, blame: nil})
      end
    end
  end
end
