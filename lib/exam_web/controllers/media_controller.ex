defmodule ExamWeb.MediaController do
  use ExamWeb, :controller
  import Plug.Conn
  import Ecto.Query, only: [from: 2]
  use Ecto.Repo, otp_app: :exam, adapter: Ecto.Adapters.Postgres
  alias ExCloudinary.{Client}
  alias Exam.{Media, User}

  plug(Exam.Plugs.Auth when action in [:delete, :upload])

  def upload(conn, params) do
    file = params["file"]
    # IO.inspect(conn)

    result = Cloudex.upload(file.path)

    case result do
      {:ok, data} ->
        data = Map.take(data, [:public_id, :secure_url])
        user = Repo.get(User, conn.assigns.user.user_id)

        media_data = %{
          user_id: conn.assigns.user.user_id,
          publish_id: data.public_id,
          secure_url: data.secure_url
        }

        # changeset = Media.changeset(%Media{}, media_data)
        changeset = Ecto.build_assoc(user, :media, media_data)
        result = Repo.insert(changeset)

        case result do
          {:ok, _} -> nil
          _ -> Cloudex.delete(data.public_id)
        end

        json(conn, %{data: data, status: "ok", success: true})

      {:error, message} ->
        json(conn, %{data: {}, status: "error Data base", success: false})
    end
  end

  def delete_media(conn, params) do
    id_image = params["id_image"]

    case id_image do
      nil ->
        json(conn, %{data: %{}, message: "No id_image", success: false})

      _ ->
        result = Cloudex.delete(id_image)
        # IO.inspect(result)

        case result do
          {:ok, _} -> json(conn, %{data: %{}, status: "ok", success: true})
          _ -> json(conn, %{data: %{}, status: "delete fail", success: false})
        end
    end
  end

  # def get_user_media(conn, parmas) do
  #   user_id = conn.assigns.user.user_id
  #   data = get_media(payload)
  #   json(conn, %{data: data, status: "ok", success: true})
  # end

  # defp get_media(parmas) do

  #   media = from( m in Media, where: m.user_id ==^parmas["user_id"], order_by: [desc: :id]  )

  # end
end
