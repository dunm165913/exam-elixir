defmodule ExamWeb.ExamChannel do
  use ExamWeb, :channel

  def join("exam:" <> exam_id, payload, socket) do
    if authorized?(payload) do
      {:ok, %{data: %{}},  socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    IO.inspect("ASDadsadadssa")
    {:reply, {:ok, payload}, socket}
  end

  def handle_in("test", payload, socket) do
    IO.inspect(payload)
    handle_in("shout", payload, socket)
    # {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (exam:lobby).
  def handle_in("shout", payload, socket) do
  
    broadcast(socket, "shout", %{data: "Dsfsaddsgsfg  sdasg"})
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(payload) do
    IO.inspect(payload)

    case Map.has_key?(payload, "access_token") && Map.has_key?(payload, "id_exam") do
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