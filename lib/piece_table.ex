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
          edited: [tuple()],
          index: integer()
        }

  defstruct original: "", result: "", edited: [], index: 0

  @doc """
  Creates a new PieceTable struct. This is intended the only method to build it.

  ## Parameters 
  - `text` (String.t()): The initial content of the piece table. 

  ## Returns
  - `{:ok, %PieceTable{}}`
  - `{:error, "original text is not a string"}`

  ## Examples

      iex> PieceTable.new("test")
      {:ok, %PieceTable{original: "test", result: "test", edited: [{:keep, 4}]}}

  """
  @spec new(String.t()) :: {:ok, PieceTable.t()} | {:error, String.t()}
  def new(text) when is_binary(text) do
    pt = %__MODULE__{
      original: text,
      # For fast access I'll keep the resulting string after all operations are applied
      # it's important to keep this always up to date otherwise the whole implementation 
      # will break
      result: text,
      edited: [{:keep, String.length(text)}],
      index: 0
    }

    {:ok, pt}
  end

  def new(_), do: {:error, "original text is not a string"}

  @doc """
  Creates a new PieceTable struct. This is intended the only method to build it.

  ## Parameters 
  - `text` (String.t()): The initial content of the piece table. 

  ## Returns `%PieceTable{}`

  ## Examples

      iex> PieceTable.new!("test")
      %PieceTable{original: "test", result: "test", edited: [{:keep, 4}]}

  """
  @spec new!(String.t()) :: PieceTable.t()
  def new!(text), do: text |> new() |> handle_result()

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
      {:ok, %PieceTable{original: "Initial content", index: 0, result: "Initial content, before", edited: [{:add, ", before", 15}, {:keep, 15}]}}
  """
  @spec insert(PieceTable.t(), String.t(), integer()) ::
          {:ok, PieceTable.t()} | {:error, String.t()}
  def insert(%__MODULE__{} = table, "", _), do: {:ok, table}

  def insert(%__MODULE__{} = table, text, position)
      when is_binary(text) and is_integer(position) and position >= 0 do
    {:ok, update_piece_table(table, {:add, text, position})}
  end

  def insert(_, _, _), do: {:error, "invalid arguments"}

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
      %PieceTable{original: "Initial content", result: "Initial content, before", index: 0, edited: [{:add, ", before", 15}, {:keep, 15}]}
  """
  @spec insert!(PieceTable.t(), String.t(), integer()) :: PieceTable.t()
  def insert!(table, text, position), do: table |> insert(text, position) |> handle_result()

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
      {:ok, %PieceTable{original: "Initial content", result: "Init content", index: 0, edited: [{:remove, "ial", 4}, {:keep, 15}]}}
  """
  @spec delete(PieceTable.t(), integer(), integer()) ::
          {:ok, PieceTable.t()} | {:error, String.t()}
  def delete(%__MODULE__{} = table, _, 0), do: {:ok, table}

  def delete(%__MODULE__{} = table, position, length)
      when is_integer(position) and is_integer(length) and length > 0 do
    # To allow reverting a change I'm saving the string instead of the length, so a remove becomes an insert on undo.
    # length will be simply calculated from the length of the string
    text = String.slice(table.result, position, length)
    {:ok, update_piece_table(table, {:remove, text, position})}
  end

  def delete(_, _, _), do: {:error, "invalid arguments"}

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
      %PieceTable{original: "Initial content", result: "Init content", index: 0, edited: [{:remove, "ial", 4}, {:keep, 15}]}
  """
  @spec delete!(PieceTable.t(), integer(), integer()) :: PieceTable.t()
  def delete!(table, position, length), do: table |> delete(position, length) |> handle_result()

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
  @spec get_text(PieceTable.t()) :: {:ok, String.t()} | {:error, String.t()}
  def get_text(%__MODULE__{} = table), do: {:ok, table.result}

  def get_text(_), do: {:error, "not a PieceTable struct"}

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
  def get_text!(table), do: table |> get_text() |> handle_result()

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
      {:ok, %PieceTable{original: "Initial content", result: "Initial content", edited: [{:remove, "ial", 4}, {:keep, 15}], index: 1}}
  """
  @spec undo(PieceTable.t()) ::
          {:ok, PieceTable.t()} | {:first, PieceTable.t()} | {:error, String.t()}
  def undo(%__MODULE__{index: index, edited: edited} = table) do
    # Move the index to previous change
    prev_state_index = index + 1

    case Enum.at(edited, index) do
      {:add, edit, pos} ->
        result = apply_change(table, {:remove, edit, pos})
        {:ok, struct(table, %{result: result, index: prev_state_index})}

      {:remove, edit, pos} ->
        result = apply_change(table, {:add, edit, pos})
        {:ok, struct(table, %{result: result, index: prev_state_index})}

      _ ->
        {:first, table}
    end
  end

  def undo(_), do: {:error, "not a PieceTable struct"}

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
      %PieceTable{original: "Initial content", result: "Initial content", edited: [{:remove, "ial", 4}, {:keep, 15}], index: 1}
  """
  @spec undo!(PieceTable.t()) :: PieceTable.t()
  def undo!(table), do: table |> undo() |> handle_result()

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
      {:ok, %PieceTable{original: "Initial content", result: "Init content", edited: [{:remove, "ial", 4}, {:keep, 15}], index: 0}}
  """
  @spec redo(PieceTable.t()) ::
          {:ok, PieceTable.t()} | {:last, PieceTable.t()} | {:error, String.t()}
  def redo(%__MODULE__{} = table) do
    # Move index to next change 
    next_state_index = table.index - 1

    case Enum.at(table.edited, next_state_index) do
      {:add, _, _} = change ->
        result = apply_change(table, change)
        {:ok, struct(table, %{result: result, index: next_state_index})}

      {:remove, _, _} = change ->
        result = apply_change(table, change)
        {:ok, struct(table, %{result: result, index: next_state_index})}

      _ ->
        {:last, table}
    end
  end

  def redo(_), do: {:error, "not a PieceTable struct"}

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
      %PieceTable{original: "Initial content", result: "Init content", edited: [{:remove, "ial", 4}, {:keep, 15}], index: 0}
  """
  @spec redo!(PieceTable.t()) :: PieceTable.t()
  def redo!(table), do: table |> redo() |> handle_result()

  defp handle_result({status, result}) when status in [:ok, :last, :first], do: result
  defp handle_result({:error, msg}), do: raise(ArgumentError, msg)

  defp update_piece_table(table, change) do
    attrs =
      Map.from_struct(table)
      # Lists in Elixir are linked lists. For efficiency prepend to the list of changes
      |> update_in([:edited], &[change | &1])
      |> Map.put(:result, apply_change(table, change))

    struct(table, attrs)
  end

  defp apply_change(%{result: str}, {:add, edit, pos}) do
    [String.slice(str, 0, pos), edit, String.slice(str, pos..-1)]
    |> Enum.reduce("", fn string, acc ->
      # Joining strings in this way is more efficient as it doesn't make copies (unlike `<>`)
      IO.iodata_to_binary([acc, string])
    end)
  end

  defp apply_change(%{result: str}, {:remove, edit, pos}) do
    start = pos + String.length(edit)

    # Fixme: would be nice to find a better way...
    [String.slice(str, 0, pos), String.slice(str, start..-1)]
    |> Enum.reduce("", fn string, acc ->
      # Joining strings in this way is more efficient as it doesn't make copies (unlike `<>`)
      IO.iodata_to_binary([acc, string])
    end)
  end
end
