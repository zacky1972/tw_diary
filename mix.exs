defmodule TwDiary.MixProject do
  use Mix.Project

  def project do
    [
      app: :tw_diary,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      applications: [:timex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 3.1"},
      {:timex, "~> 3.1"},
      {:number, "~> 0.5.7"},
      {:httpoison, "~> 1.0"},
      {:flow, "~> 0.14"}
    ]
  end
end
