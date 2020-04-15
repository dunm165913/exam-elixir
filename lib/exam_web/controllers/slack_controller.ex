defmodule ExamWeb.SlackController do
  use ExamWeb, :controller
  import Plug.Conn

  def index(conn, params) do
    # IO.inspect(params)
  end

  def handel(conn, params) do
    # # # IO.inspect(params)
    # send_resp(conn, 200, params["challenge"])
    result = reply_message(params["event"])
    json(conn, %{text: "Hi you, I'm comming"})
  end

  defp reply_message(event) do
    body = %{
      thread_ts: event["thread_ts"],
      text: "Hi, Cant i hehp you? :rice:"
    }

    case Map.has_key?(event, "bot_id") do
      true ->
        nil

      false ->
        # IO.inspect(body)
        HTTPoison.post(
          "https://hooks.slack.com/services/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",
          Jason.encode!(body),
          [{"Content-type", "application/json"}],
          recv_timeout: 45000
        )
    end
  end
end
