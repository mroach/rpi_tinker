defmodule Tinker.MixProject do
  use Mix.Project

  def project do
    [
      app: :tinker,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Tinker.Application, []},
      applications: [:nerves_io_rc522],
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:circuits_gpio, "~> 0.4.1"},
      {:circuits_spi, "~> 0.1.3"},
      {:nerves_io_rc522, "~> 0.1.0"}
    ]
  end
end
