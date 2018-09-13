defmodule TwDiary do
  require HTTPoison
  @moduledoc """
  Documentation for TwDiary.
  """

  @http ~r/^(?<text>.*)(?<url>http[s]?:\/\/[_A-z0-9\/\.]*)(?<rest>\s*.*)$/

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
      |> Enum.map(& &1[:text])
      |> Enum.reject(& Regex.match?(~r/RT/, &1))
#      |> Enum.map(& escape_image(&1))
      |> Enum.map(& "<p>#{&1}</p>")
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
    m = if match["url"] do
      HTTPoison.start
      page = HTTPoison.get(match["url"])
      |> case do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> 
          IO.puts "ok"
          body
        {:ok, %HTTPoison.Response{status_code: _}} -> 
          IO.puts "error"
          ""
        {:error, %HTTPoison.Error{reason: _}} -> 
          IO.puts "error"
          ""
      end
      Regex.named_captures(~r/<img src=\"(?<url>\")/, page)
    else
      nil
    end
    Regex.replace(@http, text, "<p>#{match["text"]}</p>#{if m do "<img src=\"#{m["url"]}\"></img>" end}<p>#{match["rest"]}</p>")
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

  def image_kl() do
    HTTPoison.start
    tweets()
    |> Enum.map(& &1[:text])
    |> Enum.reject(& Regex.match?(~r/RT/, &1))
    |> Enum.filter(& Regex.match?(@http, &1))
    |> Enum.map(& Regex.named_captures(@http, &1)["url"])
    |> Flow.from_enumerable()
    |> Flow.map(& {String.to_atom(&1), 
      (&1
      |> HTTPoison.get()
      |> case do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> 
          body
        {:ok, %HTTPoison.Response{status_code: _}} -> 
          nil
        {:error, %HTTPoison.Error{reason: _}} -> 
          nil
        end
      )})
    |> Flow.filter(& elem(&1, 1))
    |> Flow.map(& extract_image_url(&1))
    |> Flow.map(& {elem(&1, 0),
    (elem(&1, 1)
    |> HTTPoison.get()
    |> case do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> 
          body
        {:ok, %HTTPoison.Response{status_code: _}} -> 
          nil
        {:error, %HTTPoison.Error{reason: _}} -> 
          nil
        end
    |> fn (data) ->
        path = "images/#{url2path(Atom.to_string(elem(&1, 0)))}"
        File.write!(path, data)
        path
      end.()
    )})
    |> Flow.map(& {elem(&1, 0), (
      match = "file #{elem(&1, 1)}"
      |> to_charlist
      |> :os.cmd
      |> to_string
      |> fn x -> Regex.named_captures(~r/(?<ext>(JPEG)|(PNG)|(gzip)) ((image)|(compressed)) data/, x) end.()
      path = "#{elem(&1, 1)}#{if match["ext"] do "." end}#{match["ext"]}"
      File.rename(elem(&1, 1), path)
      path 
    )})
    |> Enum.to_list()
  end

  def url2path(url) do
    path = Regex.replace(~r/http[s]?:\/\//, url, "")
    Regex.replace(~r/\//, path, "_")
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

  def extract_image_url({url, string}) do
    if Regex.match?(~r/<!DOCTYPE html>/, string) do
      match = Regex.named_captures(~r/<img.*src=\"(?<url>.*)\"/U, string)
      {url, match["url"]}
    else
      # need to download and upload
      {url, Atom.to_string(url)}
    end
  end
end
