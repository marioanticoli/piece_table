defmodule PieceTableTest do
  use ExUnit.Case
  doctest PieceTable

  describe "new/1" do
    test "with string returns ok" do
      str = "my test"

      expected =
        {:ok,
         make_piece_table(%{original: str, result: str, edited: [{:keep, String.length(str)}]})}

      assert expected == PieceTable.new(str)
    end

    test "with anything else returns error" do
      expected = {:error, "original text is not a string"}

      assert expected == PieceTable.new(1)
      assert expected == PieceTable.new(nil)
      assert expected == PieceTable.new(1.3)
      assert expected == PieceTable.new(true)
    end
  end

  describe "new!/1" do
    test "return a piece table struct" do
      str = "my test"

      expected =
        make_piece_table(%{original: str, result: str, edited: [{:keep, String.length(str)}]})

      assert expected == PieceTable.new!(str)
    end

    test "raise an error" do
      assert_raise(ArgumentError, fn -> PieceTable.new!(1) end)
    end
  end

  describe "insert/3" do
    test "updates the list of operations" do
      str = "my test"
      attrs = %{original: str, edited: [{:keep, String.length(str)}], result: str}
      table = make_piece_table(attrs)

      edit = "super "
      pos = 3

      updated_attrs =
        Map.merge(attrs, %{
          result: "my super test",
          index: 1,
          edited: [{:add, edit, pos}, {:keep, 7}]
        })

      expected = {:ok, make_piece_table(updated_attrs)}

      assert expected == PieceTable.insert(table, edit, pos)
    end

    test "does nothing on empty string" do
      table = make_piece_table(%{original: "my test", edited: [{:keep, 7}]})
      pos = 3
      expected = {:ok, table}

      assert expected == PieceTable.insert(table, "", pos)
    end

    test "returns error if table is not a PieceTable" do
      attrs = %{original: "my test", edited: [{:keep, 7}]}

      expected = {:error, "invalid arguments"}

      assert expected == PieceTable.insert(attrs, "anything", 3)
    end

    test "returns error if edit is not a string" do
      attrs = %{original: "my test", edited: [{:keep, 7}]}
      table = make_piece_table(attrs)

      expected = {:error, "invalid arguments"}

      assert expected == PieceTable.insert(table, false, 3)
    end

    test "returns error if position is not a positive integer" do
      attrs = %{original: "my test", edited: [{:keep, 7}]}
      table = make_piece_table(attrs)

      expected = {:error, "invalid arguments"}

      assert expected == PieceTable.insert(table, "other ", -1)
      assert expected == PieceTable.insert(table, "other ", nil)
    end
  end

  describe "insert!/3" do
    test "updates the list of operations" do
      str = "my test"
      attrs = %{original: str, edited: [{:keep, String.length(str)}], result: str}
      table = make_piece_table(attrs)

      edit = "super "
      pos = 3

      updated_attrs =
        Map.merge(attrs, %{
          result: "my super test",
          index: 1,
          edited: [{:add, edit, pos}, {:keep, 7}]
        })

      expected = make_piece_table(updated_attrs)

      assert expected == PieceTable.insert!(table, edit, pos)
    end

    test "raises if invalid arguments" do
      attrs = %{original: "my test", edited: [{:keep, 7}]}

      assert_raise(ArgumentError, fn -> PieceTable.insert!(attrs, "anything", 3) end)
    end
  end

  describe "delete/3" do
    test "updates the list of operations" do
      attrs = %{original: "my test", result: "my test", edited: [{:keep, 7}]}
      table = make_piece_table(attrs)

      pos = 0
      length = 3

      updated_attrs =
        Map.merge(attrs, %{result: "test", index: 1, edited: [{:remove, "my ", pos}, {:keep, 7}]})

      expected = {:ok, make_piece_table(updated_attrs)}

      assert expected == PieceTable.delete(table, pos, length)
    end

    test "does nothing on 0 length" do
      table = make_piece_table(%{original: "my test", edited: [{:keep, 7}]})
      expected = {:ok, table}

      assert expected == PieceTable.delete(table, 3, 0)
    end

    test "returns error if edit is not a string" do
      attrs = %{original: "my test", edited: [{:keep, 7}]}
      table = make_piece_table(attrs)

      expected = {:error, "invalid arguments"}

      assert expected == PieceTable.delete(table, false, 3)
    end

    test "returns error if position is not a positive integer" do
      attrs = %{original: "my test", edited: [{:keep, 7}]}
      table = make_piece_table(attrs)

      expected = {:error, "invalid arguments"}

      assert expected == PieceTable.delete(table, "other ", -1)
      assert expected == PieceTable.delete(table, "other ", nil)
    end
  end

  describe "delete!/3" do
    test "updates the list of operations" do
      attrs = %{original: "my test", edited: [{:keep, 7}], result: "my test"}
      table = make_piece_table(attrs)

      pos = 0
      length = 3

      updated_attrs =
        Map.merge(attrs, %{result: "test", index: 1, edited: [{:remove, "my ", pos}, {:keep, 7}]})

      expected = make_piece_table(updated_attrs)

      assert expected == PieceTable.delete!(table, pos, length)
    end

    test "raises if invalid arguments" do
      attrs = %{original: "my test", edited: [{:keep, 7}]}

      assert_raise(ArgumentError, fn -> PieceTable.delete!(attrs, false, 3) end)
    end
  end

  describe "get_text/1" do
    test "it returns the edited text" do
      str = "my test"

      table =
        make_piece_table(%{original: str, result: str, edited: [{:keep, String.length(str)}]})

      expected = {:ok, "my test"}

      assert expected == PieceTable.get_text(table)
    end

    test "it returns an error when not a piece table" do
      str = "my test"
      not_a_table = %{original: str, result: str, edited: [{:keep, String.length(str)}]}
      expected = {:error, "not a PieceTable struct"}

      assert expected == PieceTable.get_text(not_a_table)
    end
  end

  describe "get_text!/1" do
    test "it returns the edited text" do
      str = "my test"

      table =
        make_piece_table(%{original: str, result: str, edited: [{:keep, String.length(str)}]})

      expected = "my test"

      assert expected == PieceTable.get_text!(table)
    end

    test "it raises when not a piece table" do
      str = "my test"
      not_a_table = %{original: str, result: str, edited: [{:keep, String.length(str)}]}

      assert_raise(ArgumentError, fn -> PieceTable.get_text!(not_a_table) end)
    end
  end

  describe "undo/1" do
    test "undo changes" do
      assert 1 == 0
    end

    test "doesn't do anything when already at first change" do
      assert 1 == 0
    end
  end

  describe "redo/1" do
    test "redo changes" do
      assert 1 == 0
    end

    test "doesn't do anything when already at last change" do
      assert 1 == 0
    end
  end

  defp make_piece_table(attrs), do: struct(PieceTable, attrs)
end
