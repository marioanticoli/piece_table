defmodule PieceTable.Change do
  @moduledoc """
  A struct to hold changes in the PieceTable

  ## Usage

  ```elixir
  iex> PieceTable.Change.new!(:ins, "test", 3, "bob")
  %PieceTable.Change{change: :ins, position: 3, text: "test", blame: "bob"}
  ```

  """

  @type t :: %__MODULE__{
          change: atom(),
          text: String.t(),
          position: integer(),
          blame: any()
        }

  @enforce_keys [:change, :text, :position]
  defstruct [:change, :text, :position, :blame]

  @doc """
  Creates a new PieceTable.Change struct. This is intended the only method to build it.

  ## Parameters 
  - `change` (atom()): The operation it represents [:ins | :del]
  - `text` (String.t()): The text to edit
  - `position` (integer()): The position at which the edit occurs
  - `blame` (any()): An optional ID to track who created the change

  ## Returns
  - `{:ok, %PieceTable.Change{}}`
  - `{:error, :wrong_arguments}`

  ## Examples

      iex> PieceTable.Change.new(:ins, "test", 4, nil)
      {:ok, %PieceTable.Change{change: :ins, text: "test", position: 4, blame: nil}}

  """
  @spec new(atom(), String.t(), integer(), any()) ::
          {:ok, PieceTable.Change.t()} | {:error, :wrong_arguments}
  def new(change, text, position, blame)
      when change in [:ins, :del] and is_binary(text) and is_integer(position) and position >= 0 do
    ch = %__MODULE__{change: change, text: text, position: position, blame: blame}

    {:ok, ch}
  end

  def new(_, _, _, _), do: {:error, :wrong_arguments}

  @doc """
  Creates a new PieceTable.Change struct. This is intended the only method to build it.

  ## Parameters 
  - `change` (atom()): The operation it represents [:ins | :del]
  - `text` (String.t()): The text to edit
  - `position` (integer()): The position at which the edit occurs
  - `blame` (any()): An optional ID to track who created the change

  ## Returns
  - `%PieceTable.Change{}`

  ## Examples

      iex> PieceTable.Change.new!(:ins, "test", 4, nil)
      %PieceTable.Change{change: :ins, text: "test", position: 4, blame: nil}

  """
  @spec new!(atom(), String.t(), integer(), any()) :: PieceTable.Change.t()
  def new!(change, text, position, blame),
    do: new(change, text, position, blame) |> raise_or_return()

  # handle responses, raises if :error atom
  defp raise_or_return({:error, args}), do: raise(ArgumentError, inspect(args))
  defp raise_or_return({:ok, result}), do: result

  @doc """
  Inverts the operation of a PieceTable.Change struct. 

  ## Parameters 
  - `chg` (PieceTable.Change.t()): The change to invert 

  ## Returns 
  - `{:ok, %PieceTable.Change{}}`
  - `{:error, :wrong_argument}`

  ## Examples 

      iex> PieceTable.Change.invert(%PieceTable.Change{change: :ins, text: "random", position: 5, blame: nil})
      {:ok, %PieceTable.Change{change: :del, text: "random", position: 5, blame: nil}}
  """
  @spec invert(PieceTable.Change.t()) :: {:ok, PieceTable.Change.t()} | {:error, any()}
  def invert(%__MODULE__{change: :ins} = chg), do: {:ok, Map.put(chg, :change, :del)}
  def invert(%__MODULE__{change: :del} = chg), do: {:ok, Map.put(chg, :change, :ins)}
  def invert(_), do: {:error, :wrong_argument}

  @doc """
  Inverts the operation of a PieceTable.Change struct. 

  ## Parameters 
  - `chg` (PieceTable.Change.t()): The change to invert 

  ## Returns 
  - `%PieceTable.Change{}`

  ## Examples 

      iex> PieceTable.Change.invert(%PieceTable.Change{change: :ins, text: "random", position: 5, blame: nil})
      {:ok, %PieceTable.Change{change: :del, text: "random", position: 5, blame: nil}}
  """
  @spec invert!(PieceTable.Change.t()) :: PieceTable.Change.t()
  def invert!(chg), do: chg |> invert() |> raise_or_return()
end
