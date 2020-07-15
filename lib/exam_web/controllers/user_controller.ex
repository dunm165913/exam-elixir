defmodule ExamWeb.UserController do
  alias ExamWeb.{Tool}
  use ExamWeb, :controller
  import Plug.Conn
  import Ecto.Query, only: [from: 2]
  use Ecto.Repo, otp_app: :exam, adapter: Ecto.Adapters.Postgres
  plug(Exam.Plugs.Auth when action in [:index, :info, :me])

  alias Exam.User
  alias Exam.Friend

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
    user = from(u in User, where: u.email == ^email and u.status == "active")
    data = Repo.one(user)
    # IO.inspect(data)

    case data do
      nil ->
        json(conn, %{
          data: %{},
          status: "No user or user has been locked, please contact admin to resolve it",
          success: false
        })

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
                  role: data.role,
                  name: data.name
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
                json(conn, %{data: %{}, message: "Kiểm tra lại thông tin", success: false})

              {:ok, _ABC} ->
                json(conn, %{data: %{}, message: "ok", success: true})
            end

          _ ->
            json(conn, %{data: %{}, message: "Email đã được sử dụng", success: false})
        end
    end
  end

  def search(conn, params) do
    sear = params["search"]
    data = find_user(sear)
    json(conn, data)
  end

  defp find_user(emails) do
    user =
      from(u in User,
        where: fragment("? ~ ?", u.email, ^emails) or fragment("? ~ ?", u.name, ^emails),
        select: %{
          id: u.id,
          name: u.name,
          email: u.email,
          role: u.role,
          status: u.status,
          at: u.inserted_at
        }
      )
      |> Repo.all()

    %{data: user, status: "ok", success: true}
  end

  defp find_user(id \\ nil, status \\ nil, emails) do
    s =
      if status do
        [status]
      else
        ["active", "lock"]
      end

    user =
      if id do
        from(u in User,
          where: u.id == ^id,
          select: %{
            id: u.id,
            name: u.name,
            email: u.email,
            role: u.role,
            status: u.status,
            at: u.inserted_at
          }
        )
      else
        from(u in User,
          where:
            fragment("? ~ ?", u.email, ^emails) or
              (fragment("? ~ ?", u.name, ^emails) and u.status in ^s),
          select: %{
            id: u.id,
            name: u.name,
            email: u.email,
            role: u.role,
            status: u.status,
            at: u.inserted_at
          }
        )
      end
      |> Repo.all()

    %{data: user, status: "ok", success: true}
  end

  def check_admin(conn, p) do
    token = p["token"]
    data = check_is_admin(token)
    json(conn, data)
  end

  def check_is_admin(t) do
    u =
      try do
        JsonWebToken.verify(t, %{
          key: "gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr9C"
        })
      rescue
        RuntimeError -> nil
      end

    case u do
      nil ->
        %{data: %{}, success: false}

      {:error, _} ->
        %{data: %{}, success: false}

      {:ok, du} ->
        data_u = Repo.get(User, du.user_id)

        case data_u do
          nil ->
            %{data: %{}, success: false}

          _ ->
            IO.inspect(data_u)

            if data_u.role == "admin" do
              %{data: %{}, success: true}
            else
              %{data: %{}, success: false}
            end
        end
    end
  end

  def get_list(conn, p) do
    search = p["search"]
    id = p["id"]
    status = p["status"]
    a = p["after"]

    data = find_user(id, status, search)
    json(conn, %{data: data, success: true})
  end

  def info(conn, p) do
    user_id = conn.assigns.user.user_id
    id_f = p["id_f"]

    conv =
      if id_f < user_id do
        "conv_#{id_f}_#{user_id}"
      else
        "conv_#{user_id}_#{id_f}"
      end

    re =
      from(u in User,
        join: f in Friend,
        on: f.conv == ^conv,
        where: u.id == ^id_f,
        limit: 1,
        select: %{email: u.email, name: u.name, id: u.id, status: f.status}
      )
      |> Repo.one()

    case re do
      nil ->
        u =
          from(u in User,
            where: u.id == ^id_f,
            limit: 1,
            select: %{name: u.name, id: u.id, email: u.email}
          )
          |> Repo.one()

        json(conn, %{data: u, success: true})

      _ ->
        json(conn, %{data: re, success: true})
    end
  end

  def me(conn, p) do
    user_id = conn.assigns.user.user_id

    u =
      from(u in User,
        where: u.id == ^user_id,
        limit: 1,
        select: %{
          id: u.id,
          email: u.email,
          name: u.name
        }
      )
      |> Repo.one()

    #  get List friends
    f =
      from(f in Friend,
        where: f.per1 == ^user_id or f.per2 == ^user_id,
        select: %{
          status: f.status,
          nick_name: f.nick_name
        }
      )
      |> Repo.all()

    json(conn, %{data: %{u: u, friend: f}, success: true})
  end

  def lock_account(conn, p) do
    is_admin = check_is_admin(p["access_token"])

    if is_admin.success do
      id = p["id"]
      u = Repo.get(User, id)

      case u do
        nil ->
          json(conn, %{success: false, message: "Không tìm thấy người dùng"})

        _ ->
          changeset =
            User.changeset(u, %{status: "lock"})
            |> Repo.update()

          case changeset do
            {:ok, _} ->
              json(conn, %{success: true, data: %{}})

            _ ->
              json(conn, %{success: false, message: "error db"})
          end
      end
    else
      json(conn, %{success: false, message: "not admin"})
    end
  end

  def unlock_account(conn, p) do
    is_admin = check_is_admin(p["access_token"])

    if is_admin.success do
      id = p["id"]
      u = Repo.get(User, id)

      case u do
        nil ->
          json(conn, %{success: false, message: "Không tòm thấy người dùng"})

        _ ->
          changeset =
            User.changeset(u, %{status: "active"})
            |> Repo.update()

          case changeset do
            {:ok, _} ->
              json(conn, %{success: true, data: %{}})

            _ ->
              json(conn, %{success: false, message: "error db"})
          end
      end
    else
      json(conn, %{success: false, message: "not admin"})
    end
  end
end
