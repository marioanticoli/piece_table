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
          edited: [tuple()]
        }

  defstruct original: "", result: "", edited: []

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
      edited: [{:keep, String.length(text)}]
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
  def new!(text) do
    case new(text) do
      {:ok, pt} -> pt
      {:error, msg} -> raise(ArgumentError, msg)
    end
  end

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
      {:ok, %PieceTable{original: "Initial content", result: "Initial content, before", edited: [{:keep, 15}, {:add, 15, ", before"}]}}
  """
  @spec insert(PieceTable.t(), String.t(), integer()) ::
          {:ok, PieceTable.t()} | {:error, String.t()}
  def insert(%__MODULE__{} = table, "", _), do: {:ok, table}

  def insert(%__MODULE__{} = table, text, position)
      when is_binary(text) and is_integer(position) and position >= 0 do
    {:ok, update_piece_table(table, {:add, position, text})}
  end

  def insert(_, _, _), do: {:error, "invalid arguments"}

  defp update_piece_table(table, change) do
    updated_edited = table.edited ++ [change]
    result = apply_change(table, change)
    struct(table, %{edited: updated_edited, result: result})
  end

  defp apply_change(%{result: str}, {:add, pos, edit}) do
    [String.slice(str, 0, pos), edit, String.slice(str, pos..-1)]
    |> Enum.reduce("", fn string, acc ->
      IO.iodata_to_binary([acc, string])
    end)
  end

  defp apply_change(%{result: str}, {:remove, pos, length}) do
    [String.slice(str, 0, pos), String.slice(str, (pos + length)..-1)]
    |> Enum.reduce("", fn string, acc ->
      IO.iodata_to_binary([acc, string])
    end)
  end

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
      %PieceTable{original: "Initial content", result: "Initial content, before", edited: [{:keep, 15}, {:add, 15, ", before"}]}
  """
  @spec insert!(PieceTable.t(), String.t(), integer()) :: PieceTable.t()
  def insert!(table, text, position) do
    case insert(table, text, position) do
      {:ok, t} -> t
      {:error, _} -> raise ArgumentError
    end
  end

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
      {:ok, %PieceTable{original: "Initial content", result: "Init content", edited: [{:keep, 15}, {:remove, 4, 3}]}}
  """
  @spec delete(PieceTable.t(), integer(), integer()) ::
          {:ok, PieceTable.t()} | {:error, String.t()}
  def delete(%__MODULE__{} = table, _, 0), do: {:ok, table}

  def delete(%__MODULE__{} = table, position, length)
      when is_integer(position) and is_integer(length) and length > 0 do
    {:ok, update_piece_table(table, {:remove, position, length})}
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
      %PieceTable{original: "Initial content", result: "Init content", edited: [{:keep, 15}, {:remove, 4, 3}]}
  """
  @spec delete!(PieceTable.t(), integer(), integer()) :: PieceTable.t()
  def delete!(table, position, length) do
    case delete(table, position, length) do
      {:ok, pt} -> pt
      {:error, _} -> raise ArgumentError
    end
  end

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
  def get_text!(table) do
    case get_text(table) do
      {:ok, pt} -> pt
      {:error, msg} -> raise(ArgumentError, msg)
    end
  end
end
