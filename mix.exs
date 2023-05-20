defmodule PieceTable.MixProject do
  use Mix.Project

  def project do
    [
      app: :piece_table,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Treat warnings as error
      elixirc_options: [warnings_as_errors: true]
      # TODO: check usage in CI
      # dialyzer: [
      # plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      # ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false}
    ]
  end
end
