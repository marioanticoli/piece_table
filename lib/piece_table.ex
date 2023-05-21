defmodule PieceTable do
  @moduledoc """
  The PieceTable module provides a naive implementation of the piece-table data structure
  for efficient text editing operations.

  A piece-table represents an editable buffer of text as a sequence of non-overlapping
  pieces, allowing efficient inserts, deletes, and modifications.

  ## Usage

  ```elixir
  table = PieceTable.new!("Hello, world!")
  table = PieceTable.insert!(table, "you ", 7)
  table = PieceTable.delete!(table, 10, 6)

  final_text = PieceTable.get_text(table)
  IO.puts(final_text)  # Output: "Hello, you!"

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
      {:ok, %PieceTable{original: "Initial content", index: 1, result: "Initial content, before", edited: [{:add, ", before", 15}, {:keep, 15}]}}
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
      %PieceTable{original: "Initial content", result: "Initial content, before", index: 1, edited: [{:add, ", before", 15}, {:keep, 15}]}
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
      {:ok, %PieceTable{original: "Initial content", result: "Init content", index: 1, edited: [{:remove, "ial", 4}, {:keep, 15}]}}
  """
  @spec delete(PieceTable.t(), integer(), integer()) ::
          {:ok, PieceTable.t()} | {:error, String.t()}
  def delete(%__MODULE__{} = table, _, 0), do: {:ok, table}

  def delete(%__MODULE__{} = table, position, length)
      when is_integer(position) and is_integer(length) and length > 0 do
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
      %PieceTable{original: "Initial content", result: "Init content", index: 1, edited: [{:remove, "ial", 4}, {:keep, 15}]}
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

  @spec undo(PieceTable.t()) :: PieceTable.t()
  def undo(table) do
    prev_state_index = table.index + 1

    case Enum.at(table.edited, table.index) do
      {:add, edit, pos} ->
        result = apply_change(table, {:remove, edit, pos})
        struct(table, %{result: result, index: prev_state_index})

      {:remove, edit, pos} ->
        result = apply_change(table, {:add, edit, pos})
        struct(table, %{result: result, index: prev_state_index})

      _ ->
        table
    end
  end

  @spec redo(PieceTable.t()) :: PieceTable.t()
  def redo(table) do
    next_state_index = table.index - 1

    case Enum.at(table.edited, next_state_index) |> IO.inspect() do
      {:add, _, _} = change ->
        result = apply_change(table, change) |> IO.inspect
        struct(table, %{result: result, index: next_state_index})

      {:remove, _, _} = change ->
        result = apply_change(table, change)
        struct(table, %{result: result, index: next_state_index})

      _ ->
        table
    end
  end

  defp handle_result({:ok, result}), do: result
  defp handle_result({:error, msg}), do: raise(ArgumentError, msg)

  defp update_piece_table(table, change) do
    attrs =
      Map.from_struct(table)
      |> update_in([:edited], &[change | &1])
      |> Map.put(:result, apply_change(table, change))

    struct(table, attrs)
  end

  defp apply_change(%{result: str}, {:add, edit, pos}) do
    [String.slice(str, 0, pos), edit, String.slice(str, pos..-1)]
    |> Enum.reduce("", fn string, acc ->
      IO.iodata_to_binary([acc, string])
    end)
  end

  defp apply_change(%{result: str}, {:remove, edit, pos}) do
    start = pos + String.length(edit)

    [String.slice(str, 0, pos), String.slice(str, start..-1)]
    |> Enum.reduce("", fn string, acc ->
      IO.iodata_to_binary([acc, string])
    end)
  end
end
