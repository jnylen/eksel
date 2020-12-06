defmodule Eksel.MixProject do
  use Mix.Project

  def project do
    [
      app: :eksel,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:briefly, "~> 0.3.0"},
      {:saxy, "~> 1.3"},
      {:nimble_csv, "~> 1.1"}
    ]
  end
end
