defmodule ExamWeb.RateController do
  use ExamWeb, :controller

  import Ecto.Query, only: [from: 2]
  plug(Exam.Plugs.Auth)
  alias Exam.{User, Result, RateExam, Exam}

  # get rate of user
  @spec index(Plug.Conn.t(), nil | keyword | map) :: Plug.Conn.t()
  def index(conn, params) do
    id_exam = params["id_exam"]
    id_user = conn.assigns.user.user_id
    data = get_rate_exam_by_user(id_exam, id_user)
    json(conn, data)
  end

  # options methods
  def option(conn, params) do
    json(conn, %{})
  end

  # create a rate or update rate when it is exiested
  def create(conn, params) do
    id_exam = params["id_exam"]
    id_user = conn.assigns.user.user_id

    e = Repo.get(Exam, id_exam)
    # check cant not rate exam when not do
    if e.publish || id_user in e.list_user_do do
      rate =
      from(r in RateExam, where: r.exam_id == ^id_exam and r.user_id == ^id_user, select: r)
      |> Repo.one()

    case rate do
      nil ->
        changeset =
          RateExam.changeset(%RateExam{}, %{
            star: "#{params["rate"]}",
            content: "#{params["content"]}",
            exam_id: id_exam,
            user_id: id_user
          })

        result = Repo.insert(changeset)

        data =
          case result do
            {:ok, s} -> get_data(s)
            _ -> %{success: false, data: %{}, status: "Error when insert"}
          end

        json(conn, data)

      r ->
        changeset =
          RateExam.changeset(r, %{
            star: "#{params["rate"]}",
            content: "#{params["content"]}",
            exam_id: id_exam,
            user_id: id_user
          })

        result = Repo.update(changeset)

        data =
          case result do
            {:ok, s} -> get_data(s)
            _ -> %{success: false, data: %{}, status: "Error when update"}
          end

        json(conn, data)
    end
  else
    json(conn, %{data: %{}, message: "Cant create rate", success: false})
    end



  end

  # def get_rate_exam(_, id_user) do
  #   %{data: %{}, status: "No id_exam"}
  # end

  # def get_rate_exam(id_exam, _) do
  #   %{data: %{}, status: "No id_user"}
  # end

  # process data after get from db
  def get_data(rate) do
    case rate do
      nil ->
        %{data: %{}, status: "No data", success: false}

      _ ->
        data =
          rate
          |> Map.drop([:__meta__])
          |> Poison.encode()

        case data do
          {:ok, d} ->
            data =
              d
              |> Poison.decode!()
              |> Map.take(["content", "star", "id", "user_id", "exam_id"])

            %{data: data, success: true}

          _ ->
            %{data: %{}, status: "No data", success: false}
        end
    end
  end

  def get_rate_exam_by_user(id_exam, id_user) do
    rate =
      from(r in RateExam, where: r.user_id == ^id_user and r.exam_id == ^id_exam, select: r)
      |> Repo.one()

    get_data(rate)
  end

  def get_rate_exam_total(conn, parmas) do
    id_exam = parmas["id_exam"]
    data = get_rate_exam(id_exam)
    json(conn, %{success: true, data: data})
  end

  def get_rate_exam(id_exam) do
    rate =
      from(r in RateExam, where: r.exam_id == ^id_exam, limit: 100, select: r, preload: [:user])
      |> Repo.all()
      |> Enum.map(fn r ->
        IO.inspect(r)

        re =
          r
          |> Map.take([:content, :star, :id, :user_id, :exam_id, :user])

        user =
          re.user
          |> Map.take([:id, :email, :name])

        data =
          re
          |> Map.put(:user, user)

        data
      end)

    rate
  end
end
