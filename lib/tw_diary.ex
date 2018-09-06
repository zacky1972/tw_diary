defmodule TwDiary do
  @moduledoc """
  Documentation for TwDiary.
  """

  index_file = File.read!("data/data/js/tweet_index.js")
  map_list = index_file
  |> String.split("= ")
  |> List.last
  |> Poison.decode!
  IO.inspect map_list
end
