defmodule ExamWeb.NewController do
  use ExamWeb, :controller
  import Plug.Conn
  import Ecto.Query, only: [from: 2]
  use Ecto.Repo, otp_app: :exam, adapter: Ecto.Adapters.Postgres
  alias Exam.New

  plug(
    Exam.Plugs.Auth
    when action in [:create, :update]
  )

  def get_list_new(conn, p) do
    n =
      from(n in New,
        limit: 10,
        select: %{
          data: n.data,
          id_ref: n.id_ref,
          setting: n.setting,
          source: n.source,
          title: n.title,
          id: n.id
        }
      )
      |> Repo.all()

    json(conn, %{data: n, success: true})
  end

  def create(conn, p) do
    data = p["data"]
    id_user = conn.assigns.user.user_id
    data = Map.merge(data, %{"user_id" => id_user, "id_ref" => "e"})
    is_admin = ExamWeb.UserController.check_is_admin(p["access_token"])

    if is_admin.success do
      n =
        New.changeset(%New{}, data)
        |> Repo.insert()

      case n do
        {:ok, d} ->
          json(conn, %{data: %{}, success: true})

        _ ->
          IO.inspect(n)
          json(conn, %{data: %{}, success: false, message: "Check information"})
      end
    else
      json(conn, %{data: %{}, message: "Cant do actions", success: false})
    end
  end

  def update_note(conn, p) do
    data = p["data"] || %{}
    id = p["data"]["id"] || 0
    IO.inspect(p)
    is_admin = ExamWeb.UserController.check_is_admin(p["access_token"])

    if is_admin.success do
      n = Repo.get(New, id)

      data =
        data
        |> Map.merge(%{
          "data" => data["data"]["data"],
          "title" => data["data"]["title"]
        })

      case n do
        nil ->
          json(conn, %{data: %{}, message: "No news founded", success: false})

        _ ->
          changeset = New.changeset(n, data)

          r = Repo.update(changeset)

          case r do
            {:ok, g} ->
              json(conn, %{data: %{}, success: true})

            {:error, e} ->
              IO.inspect(e)

              json(conn, %{
                data: %{},
                message: "loi khi cap nhat du lieu, vui long kiem tra lai",
                success: false
              })
          end
      end
    else
      json(conn, %{data: %{}, message: "Cant do actions", success: false})
    end

    # json(conn, %{})
  end

  def detail(conn, p) do
    n = Repo.get(New, p["id"])

    case n do
      nil ->
        json(conn, %{data: %{}, success: false, message: "No news"})

      _ ->
        {:ok, d} =
          n
          |> Map.drop([:__meta__])
          |> Poison.encode()

        r =
          d
          |> Poison.decode!()

        json(conn, %{data: r, success: true})
    end
  end

  def new_by_admin(conn, p) do
    is_admin = ExamWeb.UserController.check_is_admin(p["access_token"])

    if is_admin.success do
      news =
        from(n in New,
          limit: 30,
          select: %{
            id: n.id,
            # user_id: n.user_id, 
            insert: n.inserted_at
          }
        )
        |> Repo.all()

      json(conn, %{data: news, success: true})
    else
      json(conn, %{data: [], succeess: false, message: "not admon"})
    end
  end
end
