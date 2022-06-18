defmodule ExamWeb.FriendController do
  use ExamWeb, :controller
  import Plug.Conn
  import Ecto.Query, only: [from: 2]
  use Ecto.Repo, otp_app: :exam, adapter: Ecto.Adapters.Postgres

  plug(
    Exam.Plugs.Auth
    when action in [:get_list_friend, :get_message, :make_friend, :accept]
  )

  alias Exam.Message
  alias Exam.User
  alias Exam.Result
  alias Exam.Friend

  def get_list_friend(conn, p) do
    id_user = conn.assigns.user.user_id

    f =
      from(f in Friend,
        where: (f.per1 == ^id_user or f.per2 == ^id_user) and f.status == "done",
        select: %{
          per1: f.per1,
          per2: f.per2,
          nick_name: f.nick_name
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
        select: %{
          message: m.message,
          id: m.id,
          setting: m.setting,
          at: m.inserted_at,
          user_info: m.user_info
        }
      )
      |> Repo.all()

    json(conn, %{data: m, success: true})

    # call infor f
  end

  def make_friend(conn, p) do
    user_id = conn.assigns.user.user_id
    name = conn.assigns.user.name
    #  find friend and checked is friend
    {idf, _} = Integer.parse("#{p["id_f"]}")

    conv =
      if idf < user_id do
        "conv_#{idf}_#{user_id}"
      else
        "conv_#{user_id}_#{idf}"
      end

    conver =
      from(f in Friend,
        where: f.conv == ^conv,
        limit: 1
      )
      |> Repo.one()

    case conver do
      nil ->
        u = Repo.get(User, idf)

        case u do
          nil ->
            json(conn, %{success: false, message: "Ko tim thay ban"})

          _ ->
            result =
              Friend.changeset(%Friend{}, %{
                "conv" => conv,
                "status" => "in_process",
                "per1" => user_id,
                "per2" => idf,
                "nick_name" => [
                  %{"id" => user_id, "nick_name" => name},
                  %{"id" => idf, "nick_name" => u.name}
                ]
              })
              |> Repo.insert()

            case result do
              {:ok, f} ->
                GenServer.cast(
                  ExamWeb.Notification,
                  {:change_status_question,
                   %{
                     "actions" => [],
                     "setting" => %{},
                     "to" => idf,
                     "media" => %{},
                     "data" => %{"message" => "#{name} đã gửi lời mời kết bạn"},
                     "from" => %{"source" => "#{name}", "user" => user_id}
                   }}
                )

                json(conn, %{success: true})

              {:error, j} ->
                IO.inspect(j)
                json(conn, %{success: false, message: "Lỗi"})
            end
        end

      _ ->
        if conver.status == "in_process" do
          json(conn, %{success: false, message: "Đang đợi phản hồi"})
        else
          json(conn, %{success: false, message: "Đã kết bạn thành công"})
        end
    end
  end

  def accept(conn, p) do
    user_id = conn.assigns.user.user_id
    name = conn.assigns.user.name

    {idf, _} = Integer.parse("#{p["id_f"]}")

    conv =
      if idf < user_id do
        "conv_#{idf}_#{user_id}"
      else
        "conv_#{user_id}_#{idf}"
      end

    f =
      from(f in Friend, where: f.conv == ^conv and f.status == "in_process", limit: 1)
      |> Repo.one()

    case f do
      nil ->
        json(conn, %{success: false, message: "trang thai ko hop le"})

      _ ->
        result =
          Friend.changeset(f, %{status: "done"})
          |> Repo.update()

        ExamWeb.Cache.set(conv, %{status: "ok"}, 180_000)

        GenServer.cast(
          ExamWeb.Notification,
          {:change_status_question,
           %{
             "actions" => [],
             "setting" => %{},
             "to" => idf,
             "media" => %{},
             "data" => %{"message" => "#{name} đã chấp nhận kết bạn"},
             "from" => %{"source" => "#{name}", "user" => user_id}
           }}
        )

        case result do
          {:ok, f} ->
            json(conn, %{success: true})

          {:error, h} ->
            IO.inspect(h)
            json(conn, %{success: false, message: "Loi cap nhat"})
        end
    end
  end

  def get_con(conv) do
    # get from cache
    i = ExamWeb.Cache.get(conv)
    IO.inspect(i)

    case ExamWeb.Cache.get(conv) do
      {:ok, data} ->
        if data.status != "nil" do
          %{success: true}
        else
          %{success: false}
        end

      _ ->
        fr =
          from(f in Friend, where: f.conv == ^conv and f.status == "done", limit: 1)
          |> Repo.one()

        case fr do
          nil ->
            ExamWeb.Cache.set(conv, %{status: "nil"}, 180_000)
            %{success: false}

          _ ->
            ExamWeb.Cache.set(conv, %{status: "ok"}, 180_000)
            %{success: true}
        end
    end
  end
end
