defmodule ExamWeb.AdsfbController do
    alias ExamWeb.{Tool}
    use ExamWeb, :controller
    import Plug.Conn
    import Ecto.Query, only: [from: 2]
    use Ecto.Repo, otp_app: :exam, adapter: Ecto.Adapters.Postgres
    
  
    alias Exam.User
  
    def index(conn, params) do
      IO.inspect(params)
      res = %{value: params["hub.challenge"], received: params}
      IO.inspect(res)
    #   json(conn, params["hub.challenge"])
    send_resp(conn, 200, params["hub.challenge"])
    end

    def handle(conn, parmas) do
        IO.inspect(parmas)
        send_resp(conn, 200, "")
    end
  
    
  end