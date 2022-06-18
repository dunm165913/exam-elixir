defmodule ExamWeb.NotificationController do
  use ExamWeb, :controller

  import Ecto.Query, only: [from: 2]
  plug(Exam.Plugs.Auth)
  alias Exam.Notification

  def create(conn, params) do
    id_user = conn.assigns.user.user_id
  end

  def index(conn, params) do
    # get notification
    id_user = conn.assigns.user.user_id
    data = get_noti("#{id_user}")
    json(conn, data)
  end

  def create_noti(data) do
    changeset =
      Notification.changeset(%Notification{}, %{
        "data" => %{},
        "media" => %{},
        "from" => %{"exam" => 1},
        "to" => "1",
        "actions" => [],
        "setting" => %{},
        "status" => "unread"
      })

    case Repo.insert(changeset) do
      {:error, changeset} ->
        IO.inspect(changeset)
        %{data: %{}, status: "Check your information", success: false}

      {:ok, _} ->
        %{data: %{}, status: "ok", success: true}
    end
  end

  def get_noti(id_user) do
    # id_user must be string
    noti =
      from(n in Notification,
        where: n.to == ^id_user,
        limit: 100,
        order_by: [desc: :id],
        select: %{
          data: n.data,
          media: n.media,
          from: n.from,
          actions: n.actions,
          setting: n.setting,
          status: n.status,
          id: n.id
        }
      )
      |> Repo.all()

    %{data: noti, success: true}
  end

  def mark_unread(conn, params) do
    id_noti = params["id_noti"]
    id_user = conn.assigns.user.user_id
    data = mark_unread_noti(id_noti, "#{id_user}")
    json(conn, data)
  end

  def mark_unread_noti(id_noti, id_user) do
    noti =
      from(n in Notification,
        where: n.id == ^id_noti and n.to == ^id_user
      )
      |> Repo.one()

    case noti do
      nil ->
        %{data: %{}, success: false, message: "No notification"}

      n ->
        changeset = Notification.changeset(n, %{"status" => "read"})

        case Repo.update(changeset) do
          {:ok, s} -> %{data: %{}, success: true}
          _ -> %{data: %{}, success: false, message: "Error when update"}
        end
    end
  end

  def mardatak_unread_all(conn, params) do
    id_user = conn.assigns.user.user_id
    data = mark_unread_all_noti("#{id_user}")
    json(conn, data)
  end

  def mark_unread_all_noti(id_user) do
    noti =
      from(n in Notification,
        where: n.to == ^id_user
      )
      |> Repo.update_all(set: [status: "read"])

    %{data: %{}, success: true}
  end

  def create_notification_exam(p) do
    changset =
      Notification.changeset(%Notification{}, Map.merge(p, %{"status" => "unread"}))
      |> Repo.insert()

    case changset do
      {:ok, f} ->
        {:ok, d} =
          f
          |> Map.drop([:__meta__])
          |> Poison.encode()

        d =
          d
          |> Poison.decode!()

        IO.inspect(d)
        # broad via socket
        ExamWeb.Endpoint.broadcast!(
          "notification:#{p["to"]}",
          "get_notification",
          d
        )

      {:error, f} ->
        IO.inspect(f)
        nil
    end
  end

  def create_notification_question(p) do
    changset =
      Notification.changeset(%Notification{}, Map.merge(p, %{"status" => "unread"}))
      |> Repo.insert()

    case changset do
      {:ok, f} ->
         {:ok, d} =
          f
          |> Map.drop([:__meta__])
          |> Poison.encode()

        d =
          d
          |> Poison.decode!()
        ExamWeb.Endpoint.broadcast!(
          "notification:#{p["to"]}",
          "get_notification",
          d
        )

      {:error, f} ->
        IO.inspect(f)
        nil
    end
  end
end
