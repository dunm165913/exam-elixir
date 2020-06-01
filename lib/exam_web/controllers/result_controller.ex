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
    re =
      from(r in Result,
        where: r.id_ref == ^id_exam and r.user_id == ^id_user
      )
      |> Repo.all()

    # count n-th do exam

    count = Enum.count(re)
    IO.inspect(count)
    # filter the exam inprocess
    r =
      re
      |> Enum.filter(fn o ->
        o.status == "in_process"
      end)

    # alaway false with custom_exam
    has_protect_mark_default =
      if count > 0 do
        true
      else
        false
      end

    case Enum.count(r) do
      0 ->
        changeset =
          Result.changeset(%Result{}, %{
            "result" => [],
            "id_ref" => id_exam,
            "user_id" => id_user,
            "setting" => %{"n-th" => count + 1, "protect_mark" => has_protect_mark_default},
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

      _ ->
        IO.inspect(r)

        da_result =
          r
          |> Enum.at(0)
          |> Map.take([:id, :result, :setting])

        %{success: true, data: da_result}
    end
  end

  def save_snapshort_exam(conn, parmas) do
    client_ans = parmas["ans"]
    id_exam = parmas["id_exam"]
    id_user = conn.assigns.user.user_id
    id_ref = parmas["id_ref"]
    currentTime = parmas["currentTime"]
    protect_mark = parmas["protect_mark"] || false

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
        {:ok, now} = DateTime.now("Etc/UTC")

        if(
          Map.has_key?(r.setting, "start_time")
          # && DateTime.diff(now, r.setting["start_time"]) < 1000 * 1.5 * r.setting["num"]
        ) do
          # only change protect mark if n-th > 1
          has_protect_mark =
            if r.setting["n-th"] > 1 do
              protect_mark
            else
              false
            end

          changeset =
            Result.changeset(r, %{
              "result" => client_ans,
              "setting" =>
                Map.merge(r.setting, %{
                  "currentTime" => currentTime,
                  "protect_mark" => has_protect_mark
                })
            })

          case Repo.update(changeset) do
            {:ok, struct} -> json(conn, %{success: true, data: %{}})
            _ -> json(conn, %{success: false, data: %{}})
          end
        else
          json(conn, %{success: false, data: %{}})
        end
    end
  end

  def start_exam(conn, parmas) do
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

    exam = ExamWeb.ExamController.get_exam(id_exam, false, id_user)
    # IO.inspect(current_result)

    case current_result do
      nil ->
        json(conn, %{success: false, status: "Not result"})

      r ->
        IO.inspect(r.setting)

        if Map.has_key?(r.setting, "start_time") do
          json(conn, %{success: true, data: %{"start_time" => r.setting["start_time"]}})
        else
          {:ok, now} = DateTime.now("Etc/UTC")

          changeset =
            Result.changeset(r, %{
              "setting" =>
                Map.merge(r.setting, %{
                  "start_time" => now,
                  "num" => Enum.count(exam.data.question)
                })
            })

          case Repo.update(changeset) do
            {:ok, struct} ->
              IO.inspect(Enum.count(exam.data.question))

              GenServer.cast(
                ExamWeb.Process,
                {:auto_check,
                 %{
                   "id_ref" => id_ref,
                   "num" => Enum.count(exam.data.question),
                   "time" => Enum.count(exam.data.question) * 1000 * 1.5
                 }}
              )

              json(conn, %{success: true, data: %{"start_time" => now}})

            _ ->
              json(conn, %{success: false, data: %{}})
          end
        end
    end
  end

  def auto_check(id_ref) do
    result = Repo.get!(Result, id_ref)

    client_ans =
      Enum.reduce(result.result, %{}, fn d, acc ->
        acc =
          acc
          |> Map.put(d["id"], d["your_ans"])
      end)

    id_exam = result.id_ref
    id_user = result.user_id

    data = ExamWeb.ExamController.check_result_data(client_ans, id_exam, id_user, id_ref, "exam")

    ExamWeb.Endpoint.broadcast!("exam:#{id_exam}", "get_result", %{
      data: data,
      success: true
    })
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
        "id_ref" => id_ref,
        "user_id" => id_user,
        "setting" => %{},
        "source" => source,
        "status" => "done"
      })
      |> Repo.insert()

    IO.inspect(changeset)

    case changeset do
      # return id_result when successs
      {:ok, data} -> %{success: true, data: data.id}
      _ -> %{success: false, data: nil}
    end
  end

  @spec get_statistic_exam(any) :: %{data: any, success: true}
  def get_statistic_exam(id_e) do
    r =
      from(r in Result,
        join: u in User,
        on: u.id == r.user_id,
        where: r.id_ref == ^id_e and r.source == "exam",
        select: %{
          result: r.result,
          setting: r.setting,
          status: r.status,
          at: r.inserted_at,
          id: r.id,
          user: %{id: r.user_id, name: u.name, email: u.email}
        }
      )
      |> Repo.all()

    data = %{data: r, success: true}
  end

  def my_exam_done(conn, p) do
    id_user = conn.assigns.user.user_id
  end
end
