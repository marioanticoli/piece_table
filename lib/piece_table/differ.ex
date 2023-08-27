defmodule PieceTable.Differ do
  @moduledoc """
  A module to calculate the difference between a text and another text or a piece table. 

  ## Usage

  ```elixir
      iex> PieceTable.Differ.diff("test", "text")
      {:ok,
       %PieceTable{
         original: "test",
         result: "text",
         applied: [
           %PieceTable.Change{change: :ins, text: "x", position: 2},
           %PieceTable.Change{change: :del, text: "s", position: 2}
         ],
         to_apply: []
      }}
  ```

  """

  @type original_input :: PieceTable.t() | String.t()

  @doc """
  Computes the difference between the original input and a modified string using the PieceTable data structure.

  ## Parameters
  - `original` (original_input()): The original input string.
  - `modified` (String.t()): The modified string.

  ## Returns
  - `{:ok, %PieceTable{}}`: A tuple containing the modified PieceTable structure.
  - `{:error, String.t()}`: An error message indicating wrong arguments.

  ## Examples

      iex> PieceTable.Differ.diff("test", "text")
      {:ok,
       %PieceTable{
         original: "test",
         result: "text",
         applied: [
           %PieceTable.Change{change: :ins, text: "x", position: 2},
           %PieceTable.Change{change: :del, text: "s", position: 2}
         ],
         to_apply: []
      }}

      iex> PieceTable.Differ.diff("test", 42)
      {:error, "Wrong arguments"}

  """
  @spec diff(original_input(), String.t(), any()) :: {:ok, PieceTable.t()} | {:error, String.t()}
  def diff(origin, modified, blame \\ nil)
  def diff(original, modified, blame) when is_binary(original) and is_binary(modified),
    do: original |> PieceTable.new!() |> diff(modified, blame)

  # matches if no unapplied changes
  def diff(%PieceTable{to_apply: []} = table, modified, blame) when is_binary(modified) do
    {table, _, _} =
      table.result
      |> String.myers_difference(modified)
      |> Enum.reduce({table, 0, blame}, &add_edit/2)

    {:ok, table}
  end

  # matches if unapplied changes -> error
  def diff(%PieceTable{}, modified, _) when is_binary(modified), do: {:error, "unapplied changes"}
  def diff(_, _, _), do: {:error, "Wrong arguments"}

  @doc """
  Generates changes between the original input and a modified string using the PieceTable data structure.

  ## Parameters
  - `original` (original_input()): The original input string.
  - `modified` (String.t()): The modified string.

  ## Returns
  - `%PieceTable{}`: A tuple containing the modified PieceTable structure.

  ## Examples

      iex> PieceTable.Differ.diff!("test", "text")
      %PieceTable{
        original: "test",
        result: "text",
        applied: [
          %PieceTable.Change{change: :ins, text: "x", position: 2},
          %PieceTable.Change{change: :del, text: "s", position: 2}
        ],
        to_apply: []
      }

  """
  @spec diff!(String.t(), String.t(), any()) :: PieceTable.t()
  def diff!(original, modified, blame \\ nil), do: diff(original, modified, blame) |> raise_or_return()

  defp add_edit({:eq, text}, {table, pos, blame}),
    do: {table, pos + String.length(text), blame}

  defp add_edit({:ins, text}, {table, pos, blame}) do
    {:ok, table} = PieceTable.insert(table, text, pos, blame)
    pos = pos + String.length(text)
    {table, pos, blame}
  end

  defp add_edit({:del, text}, {table, pos, blame}) do
    length = String.length(text)
    {:ok, table} = PieceTable.delete(table, pos, length, blame)
    {table, pos, blame}
  end

  # handle responses, raises if :error atom
  defp raise_or_return({:ok, result}), do: result
  defp raise_or_return({:error, args}), do: raise(ArgumentError, args)
end
