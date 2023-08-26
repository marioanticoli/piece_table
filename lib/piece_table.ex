defmodule PieceTable do
  @moduledoc """
  The PieceTable module provides a naive implementation of the piece-table data structure
  for efficient text editing operations.

  A piece-table represents an editable buffer of text as a sequence of non-overlapping
  pieces, allowing efficient inserts, deletes, and modifications.

  ## Usage

  ```elixir
  iex> table = PieceTable.new!("Hello, world!")
  iex> table = PieceTable.insert!(table, "you ", 7)
  iex> table = PieceTable.delete!(table, 10, 6)
  iex> table = PieceTable.undo!(table)
  iex> table = PieceTable.redo!(table)
  iex> PieceTable.get_text!(table)
  "Hello, you!"
  ```
  """

  @type t :: %__MODULE__{
          original: String.t(),
          result: String.t(),
          applied: [tuple()],
          to_apply: [tuple()]
        }

  @enforce_keys [:original, :result, :applied]
  defstruct original: "", result: "", applied: [], to_apply: []

  alias PieceTable.Change

  @doc """
  Creates a new PieceTable struct. This is intended the only method to build it.

  ## Parameters 
  - `text` (String.t()): The initial content of the piece table. 

  ## Returns
  - `{:ok, %PieceTable{}}`
  - `{:error, "original text is not a string"}`

  ## Examples

      iex> PieceTable.new("test")
      {:ok, %PieceTable{original: "test", result: "test", applied: []}}

  """
  @spec new(String.t()) :: {:ok, PieceTable.t()} | {:error, :wrong_type_original_text}
  def new(text) when is_binary(text) do
    pt = %__MODULE__{
      original: text,
      # For fast access I'll keep the resulting string after all operations are applied
      # it's important to keep this always up to date otherwise the whole implementation 
      # will break
      result: text,
      # applied will contain the tuples of edits applied to the text 
      applied: [],
      # to_apply will contain the tuples of edits undone onto the text
      to_apply: []
    }

    {:ok, pt}
  end

  def new(_), do: {:error, :wrong_type_original_text}

  @doc """
  Creates a new PieceTable struct. This is intended the only method to build it.

  ## Parameters 
  - `text` (String.t()): The initial content of the piece table. 

  ## Returns `%PieceTable{}`

  ## Examples

      iex> PieceTable.new!("test")
      %PieceTable{original: "test", result: "test", applied: []}

  """
  @spec new!(String.t()) :: PieceTable.t()
  def new!(text), do: text |> new() |> raise_or_return()

  @doc """
  Inserts text into the PieceTable at a specified position.

  ## Parameters

  - `table` (PieceTable.t()): The PieceTable where the text will be inserted.
  - `text` (String.t()): The text to be inserted.
  - `position` (integer()): The position where the text should be inserted. The position is zero-based.

  ## Returns

  - `{:ok, PieceTable.t()}`
  - `{:error, "invalid arguments"}`

  ## Examples

      iex> {:ok, table} = PieceTable.new("Initial content")
      iex> PieceTable.insert(table, ", before", 15)
      {:ok, %PieceTable{original: "Initial content", result: "Initial content, before", applied: [%PieceTable.Change{change: :ins, text: ", before", position: 15}]}}
  """
  defguard is_valid_insert_input(text, position)
           when is_binary(text) and is_integer(position) and position >= 0

  @spec insert(PieceTable.t(), String.t(), integer(), any()) ::
          {:ok, PieceTable.t()} | {:error, :unapplied_changes | :invalid_arguments}
  def insert(table, text, position, blame \\ nil)
  # do nothing on empty string
  def insert(%__MODULE__{} = table, "", _, _), do: {:ok, table}

  # matches if no unapplied changes
  def insert(%__MODULE__{to_apply: []} = table, text, position, blame)
      when is_valid_insert_input(text, position) do
    change = Change.new!(:ins, text, position, blame)
    {:ok, update_piece_table(table, change)}
  end

  # matches if unapplied changes -> error
  def insert(%__MODULE__{}, text, position, _) when is_valid_insert_input(text, position),
    do: {:error, :unapplied_changes}

  def insert(_, _, _, _), do: {:error, :invalid_arguments}

  @doc """
  Inserts text into the PieceTable at a specified position.

  ## Parameters

  - `table` (PieceTable.t()): The PieceTable where the text will be inserted.
  - `text` (String.t()): The text to be inserted.
  - `position` (integer()): The position where the text should be inserted. The position is zero-based.

  ## Returns

  - `PieceTable.t()`

  ## Examples

      iex> table = PieceTable.new!("Initial content")
      iex> PieceTable.insert!(table, ", before", 15)
      %PieceTable{original: "Initial content", result: "Initial content, before", applied: [%PieceTable.Change{change: :ins, text: ", before", position: 15}]}
  """
  @spec insert!(PieceTable.t(), String.t(), integer(), any()) :: PieceTable.t()
  def insert!(table, text, position, blame \\ nil),
    do: table |> insert(text, position, blame) |> raise_or_return()

  @doc """
  Deletes a substring from the PieceTable starting at a specified position and with a specified length.

  ## Parameters

  - `table` (PieceTable.t()): The PieceTable from which the substring will be deleted.
  - `position` (integer()): The starting position of the substring to be deleted. The position is zero-based.
  - `length` (integer()): The length of the substring to be deleted.

  ## Returns

  - `{:ok, PieceTable.t()}`
  - `{:error, "invalid arguments"}`

  ## Examples

      iex> {:ok, table} = PieceTable.new("Initial content")
      iex> PieceTable.delete(table, 4, 3)
      {:ok, %PieceTable{original: "Initial content", result: "Init content", applied: [%PieceTable.Change{change: :del, text: "ial", position: 4}]}}
  """
  defguard valid_delete_input?(position, length)
           when is_integer(position) and position >= 0 and is_integer(length) and length > 0

  @spec delete(PieceTable.t(), integer(), integer(), any()) ::
          {:ok, PieceTable.t()} | {:error, :unapplied_changes | :invalid_arguments}
  def delete(table, position, length, blame \\ nil)
  # do nothing if deleting 0 chars
  def delete(%__MODULE__{} = table, _, 0, _), do: {:ok, table}

  # matches is no unapplied changes
  def delete(%__MODULE__{to_apply: []} = table, position, length, blame)
      when valid_delete_input?(position, length) do
    # To allow reverting a change I'm saving the string instead of the length, so a remove becomes an insert on undo.
    # length will be simply calculated from the length of the string
    text = String.slice(table.result, position, length)
    change = Change.new!(:del, text, position, blame)
    {:ok, update_piece_table(table, change)}
  end

  # matches if unapplied changes -> error
  def delete(%__MODULE__{}, position, length, _) when valid_delete_input?(position, length),
    do: {:error, :unapplied_changes}

  def delete(_, _, _, _), do: {:error, :invalid_arguments}

  @doc """
  Deletes a substring from the PieceTable starting at a specified position and with a specified length.

  ## Parameters

  - `table` (PieceTable.t()): The PieceTable from which the substring will be deleted.
  - `position` (integer()): The starting position of the substring to be deleted. The position is zero-based.
  - `length` (integer()): The length of the substring to be deleted.

  ## Returns

  - `PieceTable.t()`

  ## Examples

      iex> {:ok, table} = PieceTable.new("Initial content")
      iex> PieceTable.delete!(table, 4, 3)
      %PieceTable{original: "Initial content", result: "Init content", applied: [%PieceTable.Change{change: :del, text: "ial", position: 4}]}
  """
  @spec delete!(PieceTable.t(), integer(), integer(), any()) :: PieceTable.t()
  def delete!(table, position, length, blame \\ nil),
    do: table |> delete(position, length, blame) |> raise_or_return()

  @doc """
  Retrieves the entire text content from the PieceTable.

  ## Parameters

  - `table` (PieceTable.t()): The PieceTable from which the text will be retrieved.

  ## Returns

  - `{:ok, String.t()}`
  - `{:error, "not a PieceTable struct"}`

  ## Examples

      iex> {:ok, table} = PieceTable.new("Initial content")
      iex> table = PieceTable.delete!(table, 4, 3)
      iex> PieceTable.get_text(table)
      {:ok, "Init content"}
  """
  @spec get_text(PieceTable.t()) :: {:ok, String.t()} | {:error, :not_a_piece_table}
  def get_text(%__MODULE__{} = table), do: {:ok, table.result}

  def get_text(_), do: {:error, :not_a_piece_table}

  @doc """
  Retrieves the entire text content from the PieceTable.

  ## Parameters

  - `table` (PieceTable.t()): The PieceTable from which the text will be retrieved.

  ## Returns

  - `String.t()`

  ## Examples

      iex> {:ok, table} = PieceTable.new("Initial content")
      iex> table = PieceTable.delete!(table, 4, 3)
      iex> PieceTable.get_text!(table)
      "Init content"
  """
  @spec get_text!(PieceTable.t()) :: String.t()
  def get_text!(table), do: table |> get_text() |> raise_or_return()

  @doc """
  Undo the latest change applied to the string.

  ## Parameters

  - `table` (PieceTable.t()): The PieceTable from which the text will be retrieved.

  ## Returns

  - `{:ok, PieceTable.t()}`
  - `{:first, PieceTable.t()}`
  - `{:error, "not a PieceTable struct"}`


  ## Examples

      iex> {:ok, table} = PieceTable.new("Initial content")
      iex> table = PieceTable.delete!(table, 4, 3)
      iex> PieceTable.undo(table)
      {:ok, %PieceTable{original: "Initial content", result: "Initial content", applied: [], to_apply: [%PieceTable.Change{change: :del, text: "ial", position: 4}]}}
  """
  @spec undo(PieceTable.t()) ::
          {:ok, PieceTable.t()} | {:first, PieceTable.t()} | {:error, :not_a_piece_table}
  # exec only if there is at least 1 change already applied
  # accessing the head of a linked list with `[change | rest]` is an O(1) operation
  def undo(%__MODULE__{to_apply: to_apply, applied: [change | rest]} = table) do
    # transform an edit into its opposite: insert -> remove, remove -> insert
    result = change |> Change.invert!() |> apply_change(table)

    # prepend the reverted change to to_apply list and replace applied with the remaining operations
    updated_table = struct(table, %{result: result, to_apply: [change | to_apply], applied: rest})

    {:ok, updated_table}
  end

  # do nothing if no changes are applied
  def undo(%__MODULE__{applied: []} = table), do: {:first, table}
  def undo(_), do: {:error, :not_a_piece_table}

  @doc """
  Undo the latest change applied to the string.

  ## Parameters

  - `table` (PieceTable.t()): The PieceTable from which the text will be retrieved.

  ## Returns

  - `PieceTable.t()`


  ## Examples

      iex> {:ok, table} = PieceTable.new("Initial content")
      iex> table = PieceTable.delete!(table, 4, 3)
      iex> PieceTable.undo!(table)
      %PieceTable{original: "Initial content", result: "Initial content", applied: [], to_apply: [%PieceTable.Change{change: :del, text: "ial", position: 4}]}
  """
  @spec undo!(PieceTable.t()) :: PieceTable.t()
  def undo!(table), do: table |> undo() |> raise_or_return()

  @doc """
  Redo the next change previously undone to the string.

  ## Parameters

  - `table` (PieceTable.t()): The PieceTable from which the text will be retrieved.

  ## Returns

  - `{:ok, PieceTable.t()}`
  - `{:last, PieceTable.t()}`
  - `{:error, "not a PieceTable struct"}`

  ## Examples

      iex> {:ok, table} = PieceTable.new("Initial content")
      iex> table = PieceTable.delete!(table, 4, 3)
      iex> {:ok, table} = PieceTable.undo(table)
      iex> PieceTable.redo(table)
      {:ok, %PieceTable{original: "Initial content", result: "Init content", applied: [%PieceTable.Change{change: :del, text: "ial", position: 4}]}}
  """
  @spec redo(PieceTable.t()) ::
          {:ok, PieceTable.t()} | {:last, PieceTable.t()} | {:error, :not_a_piece_table}
  # exec only if there is at least 1 change to apply
  # accessing the head of a linked list with `[change | rest]` is an O(1) operation
  def redo(%__MODULE__{to_apply: [change | rest], applied: applied} = table) do
    result = change |> apply_change(table)

    # prepend the reapplied change to applied list and replace to_apply with the remaining operations
    updated_table = struct(table, %{result: result, applied: [change | applied], to_apply: rest})

    {:ok, updated_table}
  end

  # do nothing if all changes are already applied
  def redo(%__MODULE__{to_apply: []} = table), do: {:last, table}
  def redo(_), do: {:error, :not_a_piece_table}

  @doc """
  Redo the next change previously undone to the string.

  ## Parameters

  - `table` (PieceTable.t()): The PieceTable from which the text will be retrieved.

  ## Returns

  - `PieceTable.t()`

  ## Examples

      iex> {:ok, table} = PieceTable.new("Initial content")
      iex> table = PieceTable.delete!(table, 4, 3)
      iex> {:ok, table} = PieceTable.undo(table)
      iex> PieceTable.redo!(table)
      %PieceTable{original: "Initial content", result: "Init content", applied: [%PieceTable.Change{change: :del, text: "ial", position: 4}]}
  """
  @spec redo!(PieceTable.t()) :: PieceTable.t()
  def redo!(table), do: table |> redo() |> raise_or_return()

  # handle responses, raises if :error atom
  defp raise_or_return({status, result}) when status in [:ok, :last, :first], do: result
  defp raise_or_return({:error, msg}), do: raise(ArgumentError, inspect(msg))

  defp update_piece_table(table, %Change{} = change) do
    # get raw attributes
    attrs =
      Map.from_struct(table)
      # Lists in Elixir are linked lists. For efficiency prepend to the list of changes
      |> update_in([:applied], &[change | &1])
      # apply changes
      |> Map.put(:result, apply_change(change, table))

    struct(table, attrs)
  end

  # on insert
  defp apply_change(%Change{change: :ins, text: edit, position: pos}, %{result: str}) do
    [String.slice(str, 0, pos), edit, String.slice(str, pos..-1)]
    |> Enum.reduce("", fn string, acc ->
      # Joining strings in this way is more efficient as it doesn't make copies (unlike `<>`)
      IO.iodata_to_binary([acc, string])
    end)
  end

  # on deletion
  defp apply_change(%Change{change: :del, text: edit, position: pos}, %{result: str}) do
    start = pos + String.length(edit)

    [String.slice(str, 0, pos), String.slice(str, start..-1)]
    |> Enum.reduce("", fn string, acc ->
      # Joining strings in this way is more efficient as it doesn't make copies (unlike `<>`)
      IO.iodata_to_binary([acc, string])
    end)
  end
end
