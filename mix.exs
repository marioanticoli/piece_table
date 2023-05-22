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
      elixirc_options: [warnings_as_errors: true],
      # TODO: check usage in CI
      # dialyzer: [
      # plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      # ]
      description: description(),
      package: package(),
      source_url: "https://github.com/marioanticoli/piece_table"
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

  defp description() do
    "A piece-table data structure."
  end

  defp package() do
    [
      name: "piece_table",
      files:
        ~w(lib priv .formatter.exs mix.exs README* readme* LICENSE* license* CHANGELOG* changelog*),
      licenses: ["MIT License"],
      links: %{"Github" => "https://github.com/marioanticoli/piece_table"}
    ]
  end
end
