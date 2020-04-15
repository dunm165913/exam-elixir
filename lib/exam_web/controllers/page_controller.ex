defmodule ExamWeb.PageController do
  use ExamWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def get_data(conn, params) do
    # IO.inspect(params)
    send_resp(conn, 200, "")
  end

  def post_data(conn, params) do
    # IO.inspect(params)
    send_resp(conn, 200, "")
  end
end
