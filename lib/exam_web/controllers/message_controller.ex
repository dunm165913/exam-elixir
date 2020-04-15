defmodule ExamWeb.MessageController do
  use ExamWeb, :controller
  import Plug.Conn
  plug(Exam.Plugs.Auth)
  import Ecto.Query, only: [from: 2]
  use Ecto.Repo, otp_app: :exam, adapter: Ecto.Adapters.Postgres
  alias Exam.Message
  alias Exam.Exam

  def create_message(source, message, user_id, name) do
    changeset =
      Message.changeset(%Message{}, %{
        "source" => source || "default",
        "message" => message || "",
        "user_id" => user_id,
        "setting" => %{},
        "id_ref" => "null",
        "user_info" => %{
          "id" => user_id,
          "name" => name
        }
      })

    result = Repo.insert(changeset)
    # IO.inspect(result)

    case result do
      {:ok, data} ->
        %{data: %{}, success: true}

      _ ->
        %{data: %{}, success: false}
    end
  end

  def get_message(conn, parmas) do
    type = parmas["type"]
    messages = get_message_data(type)
    json(conn, %{success: true, data: messages})
  end

  def get_message_data(source) do
    messages =
      from(m in Message,
        where: m.source == ^source,
        limit: 100,
        select: m,
        preload: [:user]
      )
      |> Repo.all()
      |> Enum.map(fn m ->
        data = Map.take(m, [:message, :id, :user])

        user =
          m.user
          |> Map.take([:id, :email, :name])

        da =
          data
          |> Map.put(:user, nil)
          |> Map.put(:user_info, user)

        da
      end)
  end

  def create_message_exam(conn, parmas) do
    id_exam = parmas["id_exam"]
    message = parmas["message"]
    id_user = conn.assigns.user.user_id

    exam =
      from(e in Exam,
        where: e.id == ^id_exam,
        select: %{publish: e.publish, list_user_do: e.list_user_do}
      )
      |> Repo.one()

    case exam do
      nil ->
        json(conn, %{success: false, data: %{}, status: "No found exam"})

      e ->
        can_message =
          if(e.publish) do
            true
          else
            if id_user in e.list_user_do do
              true
            else
              false
            end
          end

        if can_message do
          data =
            Message.changeset(%Message{}, %{
              message: message,
              setting: %{},
              id_ref: id_exam,
              user_id: id_user,
              source: "exam_#{id_exam}"
            })
            |> Repo.insert()

          IO.inspect(data)

          case data do
            {:ok, d} -> json(conn, %{success: true, data: %{}})
            _ -> json(conn, %{success: false, data: %{}, status: "Cant create message"})
          end
        end
    end
  end

  def get_message_exam(conn, parmas) do
    source = parmas["source"]
    data = get_message_data(source)
    json(conn, %{success: true, data: data})
  end
end
