defmodule TwDiary do
  @moduledoc """
  Documentation for TwDiary.
  """

  @http ~r/^(?<text>.*)(?<url>http[s]?:\/\/.*)$/

  def json_read(file) do
    File.read!(file)
    |> String.split("= ")
    |> List.last
    |> Poison.decode!
  end

  def profile() do
    payload = json_read("data/data/js/payload_details.js")

    profile = json_read("data/data/js/user_details.js")
    |> Map.put("profile_image", profile_image_large())

    Map.merge(payload, profile)
  end

  def replace_br(string) do
    Regex.replace(~r/\r\n/, string, "<br/>")
  end

  def discard_decimal(string) do
    Regex.replace(~r/\.[0-9]+/, string, "")
  end

  def profile_mt() do
    profile = profile()

    datetime = get_datetime(profile["created_at"])

    "AUTHOR: Foo Bar\nTITLE: プロフィール\nBASENAME: filename\nSTATUS: Publish\nALLOW COMMENTS: 1\nALLOW PINGS: 1\nCONVERT BREAKS: richtext\nPRIMARY CATEGORY: News\nCATEGORY: News\nCATEGORY: Product\nDATE: #{format_datetime_header(datetime)}\nTAGS: \"Movable Type\",foo,bar\n-----\nBODY:\n<html><body><img style=\"text-align:center;width:75%;height:75%;\" src=\"#{profile["profile_image"]}\"></img><p style=\"text-align:center;font-size: large;\">#{profile["full_name"]}</p><p style=\"text-align:center;\">#{profile["screen_name"]}</p><p style=\"text-align:center;font-size:small;\"><br/>#{replace_br(profile["bio"])}<br/></p><p style=\"text-align:center;font-size:small;\">#{profile["location"]}</p><p style=\"text-align:center;font-size:small;\">#{discard_decimal(Number.Delimit.number_to_delimited(trunc(profile["tweets"])))} ツイート / #{format_datetime_japanese(datetime)}に登録</p></body></html>\n-----\n"
  end

  def convert_mt_all(tweets) do
  (tweets
  |> Enum.chunk_by(& Regex.match?(@http, &1[:text]))
  |> Enum.map(& convert_mt(&1))
  |> Enum.join("\n")
  ) <> "\n"
  end

  def convert_mt(tweets) do
    head = "--------\nAUTHOR: Foo Bar\nTITLE: #{hd(tweets)[:date] |> format_datetime_japanese} \nBASENAME: filename\nSTATUS: Publish\nALLOW COMMENTS: 1\nALLOW PINGS: 1\nCONVERT BREAKS: richtext\nPRIMARY CATEGORY: News\nCATEGORY: News\nCATEGORY: Product\nDATE: #{format_datetime_header(hd(tweets)[:date])}\nTAGS: \"Movable Type\",foo,bar\n-----\nBODY:\n"

    head 
    <> (body = tweets 
      |> Enum.map(& escape_image(&1[:text]))
      |> Enum.join("\n")

      "<html><body>#{body}</body></html>"
    )
  end

  def contents_mt() do
    tweets()
    |> Enum.chunk_by(& &1[:date])
    |> Enum.map(& convert_mt_all(&1))
  end

  def mt() do
    File.write!("tw_diary.mt", profile_mt())
    File.write!("tw_diary.mt", contents_mt(), [:append])
  end

  def escape_image(text) do
    match = Regex.named_captures(@http, text)
    Regex.replace(@http, text, "<p>#{match["text"]}</p><img src=\"#{match["url"]}\"></img>")
  end

  def all_read() do
    json_read("data/data/js/tweet_index.js")
    |> Enum.map(& &1["file_name"])
    |> Enum.map(& "data/#{&1}")
    |> Enum.map(& json_read(&1))
    |> Enum.flat_map(& &1)
  end

  def profile_image() do
    all_read()
    |> Enum.map(& &1["user"]["profile_image_url_https"])
    |> hd
  end

  def profile_image_large() do
    Regex.replace(~r/\_normal\.JPG/, profile_image(), "_400x400.JPG")
  end

  def tweets() do
    all_read()
    |> Enum.map(& %{ :text => &1["text"], :date => get_datetime(&1["created_at"])})
    |> Enum.reverse
    |> Enum.sort(& (Timex.compare(&1[:date] , &2[:date]) <= 0))
  end

  def format_datetime_japanese(datetime) do
    Timex.format!(datetime, "%Y年%m月%d日", :strftime)
  end

  def format_datetime_header(datetime) do
    Timex.format!(datetime, "%m/%d/%Y %T", :strftime)
  end

  def get_datetime(string) do
    Timex.parse!(string, "%F %T %z", :strftime)
  end
end
