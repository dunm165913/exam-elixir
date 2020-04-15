defmodule ExamWeb.UserController do
  alias ExamWeb.{Tool}
  use ExamWeb, :controller
  import Plug.Conn
  import Ecto.Query, only: [from: 2]
  use Ecto.Repo, otp_app: :exam, adapter: Ecto.Adapters.Postgres
  plug(Exam.Plugs.Auth when action in [:index])

  alias Exam.User

  def index(conn, params) do
    email = conn.assigns.user.email
    data_user = find_user(email)
    json(conn, Map.merge(data_user, %{status: "ok", success: true}))
  end

  def options(conn, params) do
    json(conn, %{})
  end

  def login(conn, params) do
    # IO.inspect(params)
    email = params["email"]
    password = params["password"]
    user = from(u in User, where: u.email == ^email)
    data = Repo.one(user)
    # IO.inspect(data)

    case data do
      nil ->
        json(conn, %{data: %{}, status: "No user", success: false})

      _ ->
        correct_pass = Bcrypt.verify_pass(password, data.password)
        # IO.inspect(correct_pass)

        case correct_pass do
          true ->
            token =
              JsonWebToken.sign(
                %{
                  user_id: data.id,
                  email: data.email,
                  role: data.role
                },
                %{key: "gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr9C"}
              )

            json(conn, %{data: %{token: token}, success: true, status: "ok"})

          false ->
            json(conn, %{data: %{}, success: false, status: "Incorect password"})
        end
    end
  end

  def login_email(conn, params) do
    email = params["email"]

    case email do
      nil ->
        json(conn, %{data: %{}, status: "No email", success: false})

      _ ->
        user = find_user(email)

        case user.success do
          true ->
            json(conn, %{data: %{}, status: "Please check your email to login", success: true})

          false ->
            json(conn, user)
        end
    end
  end

  def create(conn, params) do
    email = params["email"]

    case email do
      nil ->
        json(conn, %{data: %{}, status: "No email", success: false})

      _ ->
        user = from(u in User, where: u.email == ^email)
        data = Repo.one(user)

        case data do
          nil ->
            changeset =
              User.changeset(
                %User{},
                %{
                  name: params["name"],
                  password: Bcrypt.hash_pwd_salt(params["password"]),
                  email: params["email"],
                  role: params["role"]
                }
              )

            {:error, changeset}
            result = Repo.insert(changeset)

            case result do
              {:error, changeset} ->
                json(conn, %{data: %{}, status: "Check your information", success: false})

              {:ok, _ABC} ->
                json(conn, %{data: %{}, status: "ok", success: true})
            end

          _ ->
            json(conn, %{data: %{}, status: "Email has been used", success: false})
        end
    end
  end

  defp find_user(email) do
    user =
      from(u in User,
        where: u.email == ^email,
        select: %{
          id: u.id,
          email: u.email,
          role: u.role
        }
      )
      |> Repo.one()

    case user do
      nil -> %{data: %{}, status: "Not find user with email", success: false}
      _ -> %{data: user, status: "ok", success: true}
    end
  end
end
