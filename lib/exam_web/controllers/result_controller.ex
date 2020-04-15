defmodule ExamWeb.ResultController do
  use ExamWeb, :controller

  import Ecto.Query, only: [from: 2]
  plug(Exam.Plugs.Auth)
  alias Exam.{User, Result}

  def get_result(conn, params) do
    id_user = conn.assigns.user.user_id
    id_exam = params["id_exam"]
    # IO.inspect(id_user)
    # IO.inspect(id_exam)

    result =
      from(r in Result,
        where: r.user_id == ^id_user and r.exam_id == ^id_exam,
        select: %{
          id: r.id,
          result: r.result,
          exam_id: r.exam_id,
          user_id: r.user_id,
          create_at: r.inserted_at
        }
      )
      |> Repo.all()

    # IO.inspect(result)
    json(conn, %{data: result, status: "OK", success: true})
  end

  def create_default(id_exam, id_user, source) do
    # get created
    r =
      from(r in Result,
        where: r.id_ref == ^id_exam and r.user_id == ^id_user and r.status == "in_process"
      )
      |> Repo.one()

    case r do
      nil ->
        changeset =
          Result.changeset(%Result{}, %{
            "result" => [],
            "id_ref" => id_exam,
            "user_id" => id_user,
            "setting" => %{},
            "source" => source,
            "status" => "in_process"
          })

        case Repo.insert(changeset) do
          {:ok, data} ->
            da =
              data
              |> Map.take([:id, :result, :setting])

            %{success: true, data: da}

          _ ->
            %{success: false, data: %{}, status: "Fail when create defaul"}
        end

      data ->
        id =
          data
          |> Map.take([:id, :result, :setting])

        %{success: true, data: id}
    end
  end

  def save_snapshort_exam(conn, parmas) do
    client_ans = parmas["ans"]
    id_exam = parmas["id_exam"]
    id_user = conn.assigns.user.user_id
    id_ref = parmas["id_ref"]
    currentTime = parmas["currentTime"]

    current_result =
      from(r in Result,
        where:
          r.id == ^id_ref and r.id_ref == ^id_exam and r.user_id == ^id_user and
            r.status == "in_process"
      )
      |> Repo.one()

    # IO.inspect(current_result)

    case current_result do
      nil ->
        json(conn, %{success: false, status: "Not result"})

      r ->
        changeset =
          Result.changeset(r, %{
            "result" => client_ans,
            "setting" => %{"currentTime" => currentTime}
          })

        case Repo.update(changeset) do
          {:ok, struct} -> json(conn, %{success: true, data: %{}})
          _ -> json(conn, %{success: false, data: %{}})
        end
    end
  end

  # def create(conn, parmas)do
  #   # payload= %{
  #   #   user_id,
  #   #   result
  #   # }
  #   payload=%{
  #    "user_id" => conn.assigns.user.user_id,
  #    "data" => %{

  #    }
  #   }
  #   create_result(payload)
  # end
  # def create_result(payload) do
  #   user = Repo.get(User, payload.user_id)
  #   changeset = Ecto.build_assoc(user, :result, payload.data)
  #   case Repo.insert!(changeset) do
  #     {:ok, _} -> json(conn, %{data: %{}, status: "ok", success: true})
  #     _ -> json(conn, %{data: %{}, status: "false ", success: false})

  #   end
  # end

  def get_result_exam(conn, parmas) do
    id_exam = parmas["id_exam"]
    id_user = conn.assigns.user.user_id

    result = get_result_exam_data(id_exam)

    num_question =
      case Enum.at(result, 0) do
        nil -> 0
        d -> length(d.result)
      end

    user_data =
      if id_user do
        Enum.filter(result, fn r -> r.id_user == id_user end)
      else
        []
      end

    result_data =
      Enum.map(result, fn r ->
        length(Enum.filter(r.result, fn f -> f["result"] end))
      end)

    IO.inspect(result)

    json(conn, %{
      success: true,
      data: %{result: result_data, user: user_data, num_question: num_question}
    })

    # json(conn, %{success: true, data: %{result: result_data, user: user_data}})
  end

  def get_result_exam_data(id_exam) do
    result =
      from(r in Result,
        where: r.id_ref == ^id_exam and r.source == "exam" and r.status == "done",
        select: %{
          result: r.result,
          id_user: r.user_id,
          submit: r.inserted_at
        }
      )
      |> Repo.all()

    result
  end

  def create_result(result, id_ref, id_user, source) do
    changeset =
      Result.changeset(%Result{}, %{
        "result" => result,
        "id_ref" => "#{id_ref}",
        "user_id" => id_user,
        "setting" => %{},
        "source" => source
      })
      |> Repo.insert()

    # IO.inspect(changeset)

    case changeset do
      {:ok, data} -> %{success: true, data: %{}}
      _ -> %{success: false, data: %{}}
    end
  end
end
