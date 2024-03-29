defmodule PieceTableTest do
  use ExUnit.Case
  doctest PieceTable

  describe "new/1" do
    test "with string returns ok" do
      str = "my test"
      expected = {:ok, make_piece_table(%{original: str, result: str})}

      assert expected == PieceTable.new(str)
    end

    test "with anything else returns error" do
      expected = {:error, :wrong_type_original_text}

      assert expected == PieceTable.new(1)
      assert expected == PieceTable.new(nil)
      assert expected == PieceTable.new(1.3)
      assert expected == PieceTable.new(true)
      assert expected == PieceTable.new(self())
    end
  end

  describe "new!/1" do
    test "return a piece table struct" do
      str = "my test"
      expected = make_piece_table(%{original: str, result: str})

      assert expected == PieceTable.new!(str)
    end

    test "raise an error on wrong argument" do
      assert_raise(ArgumentError, fn -> PieceTable.new!(1) end)
    end
  end

  describe "insert/3" do
    test "updates the list of operations" do
      str = "my test"
      attrs = %{original: str, result: str}
      table = make_piece_table(attrs)

      edit = "super "
      pos = 3

      updated_attrs =
        Map.merge(attrs, %{
          result: "my super test",
          applied: [%PieceTable.Change{change: :ins, text: "super ", position: 3}]
        })

      expected = {:ok, make_piece_table(updated_attrs)}

      assert expected == PieceTable.insert(table, edit, pos)
    end

    test "does nothing on empty string" do
      table = make_piece_table(%{original: "my test"})
      pos = 3
      expected = {:ok, table}

      assert expected == PieceTable.insert(table, "", pos)
    end

    test "returns error if table is not a PieceTable" do
      attrs = %{original: "my test"}
      expected = {:error, :invalid_arguments}

      assert expected == PieceTable.insert(attrs, "anything", 3)
    end

    test "returns error if edit is not a string" do
      attrs = %{original: "my test"}
      table = make_piece_table(attrs)
      expected = {:error, :invalid_arguments}

      assert expected == PieceTable.insert(table, false, 3)
    end

    test "returns error if position is not a positive integer" do
      attrs = %{original: "my test"}
      table = make_piece_table(attrs)
      expected = {:error, :invalid_arguments}

      assert expected == PieceTable.insert(table, "other ", -1)
      assert expected == PieceTable.insert(table, "other ", nil)
    end

    test "returns error if there are changes to apply" do
      str = "my test"

      table =
        %{original: str, result: str}
        |> make_piece_table()
        |> PieceTable.insert!("super ", 3)
        |> PieceTable.undo!()

      assert {:error, :unapplied_changes} == PieceTable.insert(table, " will fail", 11)
    end
  end

  describe "insert!/3" do
    test "updates the list of operations" do
      str = "my test"
      attrs = %{original: str, result: str}
      table = make_piece_table(attrs)

      edit = "super "
      pos = 3

      updated_attrs =
        Map.merge(attrs, %{
          result: "my super test",
          applied: [%PieceTable.Change{change: :ins, text: "super ", position: 3}]
        })

      expected = make_piece_table(updated_attrs)

      assert expected == PieceTable.insert!(table, edit, pos)
    end

    test "raises if invalid arguments" do
      attrs = %{original: "my test"}

      assert_raise(ArgumentError, fn -> PieceTable.insert!(attrs, "anything", 3) end)
    end
  end

  describe "delete/3" do
    test "updates the list of operations" do
      attrs = %{original: "my test", result: "my test", applied: []}
      table = make_piece_table(attrs)

      pos = 0
      length = 3

      updated_attrs =
        Map.merge(attrs, %{
          result: "test",
          applied: [%PieceTable.Change{change: :del, text: "my ", position: 0}]
        })

      expected = {:ok, make_piece_table(updated_attrs)}

      assert expected == PieceTable.delete(table, pos, length)
    end

    test "does nothing on 0 length" do
      table = make_piece_table(%{original: "my test", applied: []})
      expected = {:ok, table}

      assert expected == PieceTable.delete(table, 3, 0)
    end

    test "returns error if edit is not a string" do
      attrs = %{original: "my test"}
      table = make_piece_table(attrs)
      expected = {:error, :invalid_arguments}

      assert expected == PieceTable.delete(table, false, 3)
    end

    test "returns error if position is not a positive integer" do
      attrs = %{original: "my test"}
      table = make_piece_table(attrs)
      expected = {:error, :invalid_arguments}

      assert expected == PieceTable.delete(table, "other ", -1)
      assert expected == PieceTable.delete(table, "other ", nil)
    end

    test "returns error if there are changes to apply" do
      str = "my test"

      table =
        %{original: str, result: str}
        |> make_piece_table()
        |> PieceTable.insert!("super ", 3)
        |> PieceTable.undo!()

      assert {:error, :unapplied_changes} == PieceTable.delete(table, 3, 1)
    end
  end

  describe "delete!/3" do
    test "updates the list of operations" do
      attrs = %{original: "my test", result: "my test"}
      table = make_piece_table(attrs)
      pos = 0
      length = 3

      updated_attrs =
        Map.merge(attrs, %{
          result: "test",
          applied: [%PieceTable.Change{change: :del, text: "my ", position: 0}]
        })

      expected = make_piece_table(updated_attrs)

      assert expected == PieceTable.delete!(table, pos, length)
    end

    test "raises if invalid arguments" do
      attrs = %{original: "my test"}

      assert_raise(ArgumentError, fn -> PieceTable.delete!(attrs, false, 3) end)
    end
  end

  describe "get_text/1" do
    test "it returns the edited text" do
      str = "my test"
      table = make_piece_table(%{original: str, result: str})
      expected = {:ok, "my test"}

      assert expected == PieceTable.get_text(table)
    end

    test "it returns an error when not a piece table" do
      str = "my test"
      not_a_table = %{original: str, result: str, applied: []}
      expected = {:error, :not_a_piece_table}

      assert expected == PieceTable.get_text(not_a_table)
    end
  end

  describe "get_text!/1" do
    test "it returns the edited text" do
      str = "my test"
      table = make_piece_table(%{original: str, result: str})
      expected = "my test"

      assert expected == PieceTable.get_text!(table)
    end

    test "it raises when not a piece table" do
      str = "my test"
      not_a_table = %{original: str, result: str}

      assert_raise(ArgumentError, fn -> PieceTable.get_text!(not_a_table) end)
    end
  end

  describe "undo/1" do
    test "undo changes" do
      str = "my test"
      attrs = %{original: str, result: str}
      table = make_piece_table(attrs)
      pos = 0
      length = 3
      table = PieceTable.delete!(table, pos, length)

      updated_attrs =
        Map.merge(attrs, %{
          result: "my test",
          to_apply: [%PieceTable.Change{change: :del, text: "my ", position: 0}]
        })

      expected = {:ok, make_piece_table(updated_attrs)}

      assert expected == PieceTable.undo(table)
    end

    test "returns tuple {:first, original_table} when already at the first change" do
      str = "my test"
      attrs = %{original: str, result: str}
      table = make_piece_table(attrs)
      pos = 0
      length = 3
      table = PieceTable.delete!(table, pos, length)

      updated_attrs =
        Map.merge(attrs, %{
          result: "my test",
          to_apply: [%PieceTable.Change{change: :del, text: "my ", position: 0}],
          applied: []
        })

      expected = {:ok, make_piece_table(updated_attrs)}

      assert expected == PieceTable.undo(table)
    end

    test "returns error if argument not a PieceTable" do
      assert {:error, :not_a_piece_table} == PieceTable.undo(false)
    end
  end

  describe "undo!/1" do
    test "un-does last change" do
      str = "my test"
      attrs = %{original: str, result: str}
      table = make_piece_table(attrs)
      pos = 0
      length = 3
      table = PieceTable.delete!(table, pos, length)

      updated_attrs =
        Map.merge(attrs, %{
          result: "my test",
          to_apply: [%PieceTable.Change{change: :del, text: "my ", position: 0}]
        })

      expected = make_piece_table(updated_attrs)

      assert expected == PieceTable.undo!(table)
    end

    test "raises when argument not a PieceTable" do
      assert_raise(ArgumentError, fn -> PieceTable.undo!(12) end)
    end
  end

  describe "redo/1" do
    test "redo changes" do
      str = "my test"
      attrs = %{original: str, result: str}
      table = make_piece_table(attrs)
      pos = 0
      length = 3
      table = PieceTable.delete!(table, pos, length)

      updated_attrs =
        Map.merge(attrs, %{
          result: "test",
          applied: [%PieceTable.Change{change: :del, text: "my ", position: 0}]
        })

      expected = {:ok, make_piece_table(updated_attrs)}

      {:ok, table} = PieceTable.undo(table)
      assert expected == PieceTable.redo(table)
    end

    test "returns tuple {:last, table} when already at last change" do
      str = "my test"
      attrs = %{original: str, result: str}
      table = make_piece_table(attrs)
      pos = 0
      length = 3
      table = PieceTable.delete!(table, pos, length)

      updated_attrs =
        Map.merge(attrs, %{
          result: "test",
          applied: [%PieceTable.Change{change: :del, text: "my ", position: 0}]
        })

      expected = {:last, make_piece_table(updated_attrs)}

      {:ok, table} = PieceTable.undo(table)
      {:ok, table} = PieceTable.redo(table)
      assert expected == PieceTable.redo(table)
    end

    test "returns error when argument not a struct" do
      assert {:error, :not_a_piece_table} == PieceTable.redo(false)
    end
  end

  describe "redo!/1" do
    test "redo changes" do
      str = "my test"
      attrs = %{original: str, result: str}
      table = make_piece_table(attrs)
      pos = 0
      length = 3
      table = PieceTable.delete!(table, pos, length)

      updated_attrs =
        Map.merge(attrs, %{
          result: "test",
          applied: [%PieceTable.Change{change: :del, text: "my ", position: 0}]
        })

      expected = make_piece_table(updated_attrs)

      {:ok, table} = PieceTable.undo(table)
      assert expected == PieceTable.redo!(table)
    end

    test "returns error when argument not a struct" do
      assert_raise(ArgumentError, fn -> PieceTable.redo!(false) end)
    end
  end

  defp make_piece_table(attrs), do: struct(PieceTable, attrs)
end
