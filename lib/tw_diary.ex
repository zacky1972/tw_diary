defmodule TwDiary do
  @moduledoc """
  Documentation for TwDiary.
  """

  def json_read(file) do
    File.read!(file)
    |> String.split("= ")
    |> List.last
    |> Poison.decode!
  end

  def all_read() do
    json_read("data/data/js/tweet_index.js")
    |> Enum.map(& &1["file_name"])
    |> Enum.map(& "data/#{&1}")
    |> Enum.map(& json_read(&1))
    |> Enum.flat_map(& &1)
    |> Enum.map(& %{ :text => &1["text"], :date => &1["created_at"]})
    |> IO.inspect
  end
end
