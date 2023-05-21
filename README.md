# PieceTable

The PieceTable module provides a naive implementation of the piece-table data structure
for efficient text editing operations.

A piece-table represents an editable buffer of text as a sequence of non-overlapping
pieces, allowing efficient inserts, deletes, and modifications.

This structure allows virtually infinite undo/redo, as long as we can keep the complete 
list of changes.

## Usage

```elixir
iex> table = PieceTable.new!("Hello, world!")
%PieceTable{
  original: "Hello, world!",
  result: "Hello, world!",
  edited: [keep: 13],
  index: 0
}

iex> table = PieceTable.insert!(table, "you ", 7)
%PieceTable{
  original: "Hello, world!",
  result: "Hello, you world!",
  edited: [{:add, "you ", 7}, {:keep, 13}],
  index: 0
}

iex> table = PieceTable.delete!(table, 10, 6)
%PieceTable{
  original: "Hello, world!",
  result: "Hello, you!",
  edited: [{:remove, " world", 10}, {:add, "you ", 7}, {:keep, 13}],
  index: 0
}

iex> table = PieceTable.undo!(table)
%PieceTable{
  original: "Hello, world!",
  result: "Hello, you world!",
  edited: [{:remove, " world", 10}, {:add, "you ", 7}, {:keep, 13}],
  index: 1
}

iex> table = PieceTable.redo!(table)
%PieceTable{
  original: "Hello, world!",
  result: "Hello, you!",
  edited: [{:remove, " world", 10}, {:add, "you ", 7}, {:keep, 13}],
  index: 0
}

iex> PieceTable.get_text(table)
"Hello, you!"
```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `piece_table` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:piece_table, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/piece_table>.

