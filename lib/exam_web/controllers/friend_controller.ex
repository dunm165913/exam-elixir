defmodule ExamWeb.FriendController do
  use ExamWeb, :controller
  import Plug.Conn
  import Ecto.Query, only: [from: 2]
  use Ecto.Repo, otp_app: :exam, adapter: Ecto.Adapters.Postgres

  plug(
    Exam.Plugs.Auth
    when action in [:get_list_friend, :get_message]
  )

  alias Exam.Message
  alias Exam.User
  alias Exam.Result
  alias Exam.Friend

  def get_list_friend(conn, p) do
    id_user = conn.assigns.user.user_id

    f =
      from(f in Friend,
        where: f.per1 == ^id_user or f.per2 == ^id_user,
        select: %{
          per1: f.per1,
          per2: f.per2
        },
        limit: 10
      )
      |> Repo.all()

    json(conn, %{data: f, success: true})
  end

  def get_message(conn, p) do
    user_id = conn.assigns.user.user_id
    {idf, _} = Integer.parse(p["idf"])

    conv =
      if idf < user_id do
        "conv_#{idf}_#{user_id}"
      else
        "conv_#{user_id}_#{idf}"
      end

    #  call message,
    m =
      from(m in Message,
        where: m.source == ^conv,
        limit: 30,
        order_by: [desc: :id],
        select: %{message: m.message, id: m.id, setting: m.setting, at: m.inserted_at, user_info: m.user_info}
      )
      |> Repo.all()

    json(conn, %{data: m, success: true})

    # call infor f
  end
end
