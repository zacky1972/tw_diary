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
    |> Enum.map(& %{ :text => &1["text"], :date => get_datetime(&1["created_at"])})
    |> Enum.reverse
    |> Enum.sort(& (Timex.compare(&1[:date] , &2[:date]) <= 0))
    |> IO.inspect
  end

  def get_datetime(string) do
    Timex.parse!(string, "%F %T %z", :strftime)
  end
end
