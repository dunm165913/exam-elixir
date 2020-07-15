defmodule ExamWeb.NotificationChannel do
  use ExamWeb, :channel
  alias Exam.Question
  alias Exam.User
  alias Exam.Result
  alias Exam.Exam
  alias Exam.Notification

  def join("notification:" <> endp, payload, socket) do
    # # IO.inspect(socket)
    if authorized?(payload) do
      {:ok, %{data: %{staus: "Connected"}}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("mark_read_notification", payload, socket) do
    #
    id_n = payload["id_n"]
    to = payload["id_user"]
    IO.inspect(payload)

    ExamWeb.NotificationController.mark_unread_noti(id_n, to)
      {:noreply, socket}
  end

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
