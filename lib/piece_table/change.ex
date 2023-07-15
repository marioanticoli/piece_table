defmodule PieceTable.Change do
  @moduledoc """
  A struct to hold changes in the PieceTable

  ## Usage

  ```elixir
  iex> table = PieceTable.Change.new!(:ins, "test", 3)
  %PieceTable.Change{change: :ins, position: 3, text: "test"}
  ```

  """

  @type t :: %__MODULE__{
          change: atom(),
          text: String.t(),
          position: integer()
        }

  @enforce_keys [:change, :text, :position]
  defstruct [:change, :text, :position]

  @doc """
  Creates a new PieceTable.Change struct. This is intended the only method to build it.

  ## Parameters 
  - `change` (atom()): The operation it represents [:ins | :del]
  - `text` (String.t()): The text to edit
  - `position` (integer()): The position at which the edit occurs

  ## Returns
  - `{:ok, %PieceTable.Change{}}`
  - `{:error, {:wrong, "edit", -1}}`

  ## Examples

      iex> PieceTable.Change.new(:ins, "test", 4)
      {:ok, %PieceTable.Change{change: :ins, text: "test", position: 4}}

  """
  @spec new(atom(), String.t(), integer()) ::
          {:ok, PieceTable.Change.t()} | {:error, {atom(), String.t(), integer()}}
  def new(change, text, position)
      when change in [:ins, :del] and is_binary(text) and is_integer(position) and
             position >= 0 do
    ch = %__MODULE__{change: change, text: text, position: position}

    {:ok, ch}
  end

  def new(_, _, _), do: {:error, "Wrong arguments"}

  @doc """
  Creates a new PieceTable.Change struct. This is intended the only method to build it.

  ## Parameters 
  - `change` (atom()): The operation it represents [:ins | :del]
  - `text` (String.t()): The text to edit
  - `position` (integer()): The position at which the edit occurs

  ## Returns
  - `%PieceTable.Change{}`

  ## Examples

      iex> PieceTable.Change.new!(:ins, "test", 4)
      %PieceTable.Change{change: :ins, text: "test", position: 4}

  """
  @spec new!(atom(), String.t(), integer()) :: PieceTable.Change.t()
  def new!(change, text, position), do: new(change, text, position) |> raise_or_return()

  # handle responses, raises if :error atom
  defp raise_or_return({:error, args}), do: raise(ArgumentError, args)
  defp raise_or_return({:ok, result}), do: result

  @doc """
  Inverts the operation of a PieceTable.Change struct. 

  ## Parameters 
  - `chg` (PieceTable.Change.t()): The change to invert 

  ## Returns 
  - `{:ok, %PieceTable.Change{}}`
  - `{:error, any}`

  ## Examples 

      iex> PieceTable.Change.invert(%PieceTable.Change{change: :ins, text: "random", position: 5})
      {:ok, %PieceTable.Change{change: :del, text: "random", position: 5}}
  """
  @spec invert(PieceTable.Change.t()) :: {:ok, PieceTable.Change.t()} | {:error, any()}
  def invert(%__MODULE__{change: :ins} = chg), do: {:ok, Map.put(chg, :change, :del)}
  def invert(%__MODULE__{change: :del} = chg), do: {:ok, Map.put(chg, :change, :ins)}
  def invert(_), do: {:error, "Wrong argument"}

  @doc """
  Inverts the operation of a PieceTable.Change struct. 

  ## Parameters 
  - `chg` (PieceTable.Change.t()): The change to invert 

  ## Returns 
  - `%PieceTable.Change{}`

  ## Examples 

      iex> PieceTable.Change.invert(%PieceTable.Change{change: :ins, text: "random", position: 5})
      {:ok, %PieceTable.Change{change: :del, text: "random", position: 5}}
  """
  @spec invert!(PieceTable.Change.t()) :: PieceTable.Change.t()
  def invert!(chg), do: chg |> invert() |> raise_or_return()
end
