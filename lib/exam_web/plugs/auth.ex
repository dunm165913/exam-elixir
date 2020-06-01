defmodule Exam.Plugs.Auth do
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, correct_auth) do
    # IO.inspect(conn.query_params["access_token"])
    case conn.query_params["access_token"] do
      nil ->
        conn
        |> send_resp(200, Jason.encode!(%{data: %{}, message: "No acctes_token", success: false}))
        |> halt()

      _ ->
        # case JsonWebToken.verify(conn.query_params["access_token"], %{
        #        key: "gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr9C"
        #      }) do
        #   {:ok, claims} -> assign(conn, :user, claims)
        #   _ ->conn
        #   |> put_resp_header("content-type", "application/json; charset=UTF-8")
        #   |> send_resp( 200, Jason.encode!(%{data: %{}, status: "Auth fail"}))
        #   |> halt()
        # end
        try do
          d =
            JsonWebToken.verify(conn.query_params["access_token"], %{
              key: "gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr9C"
            })

          case d do
            {:ok, data} ->
              assign(conn, :user, data)

            {:error, _} ->
              conn
              |> send_resp(200, Jason.encode!(%{data: %{}, message: "Auth fail", success: false}))
              |> halt()
          end
        rescue
          RuntimeError ->
            conn
            |> send_resp(200, Jason.encode!(%{data: %{}, message: "Auth fail", success: false}))
            |> halt()
        end
    end
  end
end
