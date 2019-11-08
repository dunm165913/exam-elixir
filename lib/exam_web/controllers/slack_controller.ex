defmodule ExamWeb.SlackController do
    use ExamWeb, :controller
    import Plug.Conn
  
    def index(conn, params) do
      IO.inspect(params)
    end
  
    def handel(conn, params) do
      IO.inspect(params)
      result = reply_message(params["event"])
      json(conn, %{text: "Hi you, I'm comming"})
    end
  
    defp reply_message(event) do
      body = %{
        "text" => "Hi, can i help you?"
      }
  
      case Map.has_key?(event, "bot_id") do
        true ->
          nil
  
        false ->
          HTTPoison.post(
            "https://hooks.slack.com/services/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",
            Jason.encode!(body),
            [{"Content-type", "application/json"}],
            recv_timeout: 45000
          )
      end
    end
  end