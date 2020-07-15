defmodule ExamWeb.MessageChannel do
  use ExamWeb, :channel
  alias Exam.Question
  alias Exam.User
  alias Exam.Result
  alias Exam.Exam

  alias ExamWeb.Presence

  def join("message:" <> endp, payload, socket) do
    # # IO.inspect(socket)
    if authorized?(payload) do
      # send(self(), :after_join)
      {:ok, %{data: %{staus: "Connected"}}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("send_message", payload, socket) do
    idf = payload["idf"]
    mes = payload["message"]
    user_id = payload["from"]
    user_info = payload["user_info"]
    name = user_info["name"]

    conv =
      if idf < user_id do
        "conv_#{idf}_#{user_id}"
      else
        "conv_#{user_id}_#{idf}"
      end

    # only create meeshe if existed conv
    cov = ExamWeb.FriendController.get_con(conv)
    IO.inspect(cov)

    if cov.success do
      result = ExamWeb.MessageController.create_message(conv, mes, user_id, name, "#{idf}")

      if result.success do
        # notification to user
        {:ok, send_b} =
          result.data
          |> Map.drop([:__meta__])
          |> Poison.encode()

        send_b =
          send_b
          |> Poison.decode!()

        ExamWeb.Endpoint.broadcast!(
          "message:user_#{idf}",
          "get_message",
          %{
            data: send_b,
            success: true
          }
        )

        push(socket, "get_message", %{data: send_b, success: true})
      else
        push(socket, "get_message", %{data: %{}, success: false})
      end

      {:noreply, socket}
    else
      push(socket, "get_message", %{
        data: %{message: "Bạn chưa kết nối với người này"},
        success: false
      })

      {:noreply, socket}
    end
  end

  # def handle_info(:after_join, socket) do
  #   {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
  #     online_at: inspect(System.system_time(:second))
  #   })

  #   push(socket, "presence_state", Presence.list(socket))
  #   {:noreply, socket}
  # end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client

  # Add authorization logic here as required.
  defp authorized?(payload) do
    case Map.has_key?(payload, "access_token") do
      true ->
        try do
          data_user =
            JsonWebToken.verify(payload["access_token"], %{
              key: "gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr9C"
            })
        rescue
          RuntimeError -> false
        end

      false ->
        false
    end
  end
end
