defmodule ExamWeb.QuestionController do
  alias ExamWeb.{Tool}
  use ExamWeb, :controller
  import Plug.Conn
  import Ecto.Query
  import Ecto.SubQuery
  plug(Exam.Plugs.Auth)
  use Ecto.Repo, otp_app: :exam, adapter: Ecto.Adapters.Postgres

  plug(
    Exam.Plugs.Auth
    when action in [:index, :get_random_question, :do_question, :get_new, :create]
  )

  alias Exam.Question
  alias Exam.User
  alias Exam.Result

  def index(conn, params) do
    id_question = params["id"]

    case id_question do
      nil ->
        json(conn, %{data: %{}, status: "No id question", success: false})

      _ ->
        data = get_question(id_question)

        case data do
          nil ->
            json(conn, %{data: %{}, status: "No question", success: false})

          {:ok, data} ->
            json(conn, %{data: data, status: "ok", success: true})
        end
    end
  end

  def get_random_question(conn, parmas) do
    clas = parmas["clas"] || "all"
    level = parmas["level"] || "all"
    subject = parmas["subject"] || "all"

    clas =
      if clas == "all" do
        ["10", "11", "12"]
      else
        [clas]
      end

    level =
      if level == "all" do
        ["1", "2", "3"]
      else
        [level]
      end

    subject =
      if subject == "all" do
        ["T", "L", "H"]
      else
        [subject]
      end

    q =
      from(q in Question,
        where: q.class in ^clas and q.subject in ^subject and q.level in ^level,
        order_by: fragment("RANDOM()"),
        limit: 1
      )
      |> Repo.one()

    IO.inspect(q)

    data =
      case q do
        nil ->
          %{success: false, data: %{}, message: "Error when get DB"}

        _ ->
          q =
            q
            |> Map.drop([:__meta__])
            |> Poison.encode()

          case q do
            {:ok, question} ->
              da =
                question
                |> Poison.decode!()
                |> Map.take([
                  "as",
                  "question",
                  "parent_question",
                  "type",
                  "subject",
                  "url_media",
                  "level",
                  "class",
                  "detail",
                  "id",
                  "correct_ans"
                ])

              ExamWeb.Cache.set("q_#{da["id"]}", da, 1200)

              %{success: true, data: Map.delete(da, "correct_ans")}

            _ ->
              %{success: false, data: %{}, message: "Error when get DB"}
          end
      end

    json(conn, data)
    # IO.inspect(data)
  end

  def live_question(sub, clas) do
    question = get_random(sub, clas)
    # IO.inspect("PPPPPPPP")

    if question.success do
      ExamWeb.Cache.set("live_question_#{sub}_#{clas}", question.data, 1200)

      ExamWeb.Endpoint.broadcast!(
        "question:live_#{sub}_#{clas}",
        "get_question_#{sub}_#{clas}",
        %{
          data: question,
          success: true
        }
      )
    else
      ExamWeb.Endpoint.broadcast!("question:live_#{sub}_#{clas}", "get_question_error", %{
        data: question,
        success: true
      })
    end
  end

  def do_question(conn, params) do
    id_question = params["id"]

    data = get_question(id_question)

    # IO.inspect(data)

    case data do
      nil ->
        json(conn, %{data: %{}, status: "No question", success: false})

      {:ok, data} ->
        da =
          data
          |> Map.delete("correct_ans")

        json(conn, %{data: da, status: "ok", success: true})
    end
  end

  def check_question(conn, params) do
    id_question = params["id_question"]
    id_user = conn.assigns.user.user_id
    ans = params["ans"]
    question = ExamWeb.Cache.get("q_#{id_question}")

    data =
      case question do
        {:ok, data} -> question
        _ -> get_question(id_question)
      end

    case data do
      nil ->
        json(conn, %{data: %{}, status: "No question", success: false})

      {:ok, data} ->
        if data["correct_ans"] == ans do
          result =
            ExamWeb.ResultController.create_result(
              [%{result: true, id: data["id"], your_ans: ans}],
              data["id"] || id_question,
              id_user,
              "question_#{data["subject"]}_#{data["class"]}"
            )

          ExamWeb.MarkSubject.create_mark_by_question(
            id_user,
            "#{id_question}",
            true,
            "question",
            result.data
          )

          json(conn, %{data: %{result: true}, status: "ok", success: true})
        else
          result =
            ExamWeb.ResultController.create_result(
              [%{result: false, id: data["id"], your_ans: ans}],
              data["id"] || id_question,
              id_user,
              "question_#{data["subject"]}_#{data["class"]}"
            )

          ExamWeb.MarkSubject.create_mark_by_question(
            id_user,
            "#{id_question}",
            false,
            "question",
            result.data
          )

          json(conn, %{data: %{result: false}, status: "ok", success: true})
        end
    end
  end

  @spec create(Plug.Conn.t(), nil | keyword | map) :: Plug.Conn.t()
  def create(conn, params) do
    id_user = conn.assigns.user.user_id

    changeset =
      Question.changeset(%Question{}, Map.put(params["data"] || %{}, "user_id", id_user))

    # IO.inspect(verfity_token)

    # IO.inspect(data_question)
    # changeset = Question.changeset(%Question{}, data_question)
    result = Repo.insert(changeset)
    IO.inspect(result)

    case result do
      {:error, changeset} ->
        json(conn, %{data: %{}, status: "Check your information", success: false})

      {:ok, _} ->
        json(conn, %{data: %{}, status: "ok", success: true})
    end
  end

  def get_question(id_question) do
    case id_question do
      nil ->
        nil

      _ ->
        question =
          from(q in Question, where: q.id == ^id_question and q.status == "done", select: q)
          |> Repo.one()

        case question do
          nil ->
            nil

          _ ->
            data =
              question
              |> Map.drop([:__meta__])
              |> Poison.encode()

            case data do
              {:ok, q} ->
                da =
                  q
                  |> Poison.decode!()

                da

              _ ->
                nil
            end
        end
    end
  end

  def get_random(sub, clas) do
    q =
      from(q in Question,
        where: q.class == ^clas and q.subject == ^sub and q.status == "done",
        order_by: fragment("RANDOM()"),
        limit: 1
      )
      |> Repo.one()
      |> Map.drop([:__meta__])
      |> Poison.encode()

    data =
      case q do
        {:ok, question} ->
          da =
            question
            |> Poison.decode!()
            |> Map.put("insert", DateTime.utc_now())

          # IO.inspect(da)

          ExamWeb.Cache.set("q_#{da["id"]}", da, 1200)
          # delete correct_ans
          %{success: true, data: da}

        _ ->
          %{success: false, data: %{}, status: "Error when get DB"}
      end
  end

  def get_new(conn, params) do
    clas = params["clas"] || "12"
    level = params["level"] || "1"
    subject = params["subject"] || "T"
    id_user = conn.assigns.user.user_id
    level = params["level"] || "0"

    level =
      if level == "0" do
        ["1", "2", "3"]
      else
        [level]
      end

    status = params["status"] || "all"
    # check user has condition get current mark_sub

    m = ExamWeb.MarkSubject.get_data_mark(id_user, clas, subject)

    u = m.data

    if Map.has_key?(u, :mark) && u.mark > 8 do
      q =
        case status do
          "all" ->
            from(q in Question,
              left_join: r in Result,
              on: r.id_ref == q.id and r.user_id == ^id_user and r.source == "review_question",
              where:
                q.class == ^clas and q.subject == ^subject and
                  q.status == "inreview" and q.level in ^level,
              limit: 10,
              select: %{
                question: q.question,
                url_media: q.url_media,
                as: q.as,
                id: q.id,
                at: q.inserted_at,
                level: q.level,
                result: %{
                  result: r.result,
                  status: r.status,
                  id: r.id
                }
              }
            )
            |> Repo.all()

          "done" ->
            from(q in Question,
              join: r in Result,
              on: r.id_ref == q.id and r.user_id == ^id_user and r.source == "review_question",
              where:
                q.class == ^clas and q.subject == ^subject and
                  q.status == "inreview" and q.level in ^level,
              limit: 10,
              select: %{
                question: q.question,
                url_media: q.url_media,
                as: q.as,
                id: q.id,
                at: q.inserted_at,
                level: q.level,
                result: %{
                  result: r.result,
                  status: r.status,
                  id: r.id
                }
              }
            )
            |> Repo.all()

          _ ->
            subset =
              from(r in Result,
                where: r.user_id == ^id_user and r.source == "review_question",
                select: r.id_ref
              )
              |> Repo.all()

            IO.inspect(subset)

            q =
              from(q in Question,
                where:
                  q.class == ^clas and q.subject == ^subject and
                    q.status == "inreview" and q.level in ^level and not (q.id in ^subset),
                limit: 10,
                select: %{
                  question: q.question,
                  url_media: q.url_media,
                  as: q.as,
                  id: q.id,
                  at: q.inserted_at,
                  level: q.level,
                  result: %{}
                }
              )
              |> Repo.all()
        end

      IO.inspect(q)
      json(conn, %{success: true, data: q})
    else
      json(conn, %{data: u, success: false, message: "Not enought mark"})
    end
  end

  def create_review(conn, params) do
    id_user = conn.assigns.user.user_id
    id_ref = params["id"]
    your_ans = params["your_ans"]

    # create or update the result was existed
    # get result
    r =
      from(r in Result,
        where: r.id_ref == ^id_ref and r.user_id == ^id_user and r.source == "review_question",
        limit: 1
      )
      |> Repo.one()

    case r do
      nil ->
        re =
          Result.changeset(%Result{}, %{
            "result" => [%{"id" => id_ref, "your_ans" => your_ans}],
            "id_ref" => id_ref,
            "user_id" => id_user,
            "setting" => %{},
            "source" => "review_question",
            "status" => "in process"
          })
          |> Repo.insert()

        case re do
          {:ok, ry} ->
            data =
              ry
              |> Map.take([:id, :result])

            IO.inspect(data)

            json(conn, %{data: data, success: true})

          _ ->
            json(conn, %{data: %{}, success: false, message: "Lỗi khi lưu trữ"})
        end

      _ ->
        re =
          Result.changeset(r, %{
            "result" => [%{"id" => id_ref, "your_ans" => your_ans}],
            "id_ref" => id_ref,
            "user_id" => id_user,
            "setting" => %{},
            "source" => "review_question",
            "status" => "in process"
          })
          |> Repo.update()

        case re do
          {:ok, ri} ->
            data =
              ri
              |> Map.take([:id, :result])

            json(conn, %{data: data, success: true})

          _ ->
            json(conn, %{data: %{}, success: false, message: "Lỗi khi cập nhật"})
        end
    end
  end

  def delete_submit_question_new(conn, params) do
    id_user = conn.assigns.user.user_id
    id_ref = params["id"]

    r =
      from(r in Result,
        where: r.user_id == ^id_user and r.id == ^id_ref,
        limit: 1
      )
      |> Repo.one()

    case r do
      nil ->
        json(conn, %{data: %{}, success: false, message: "No result found"})

      _ ->
        re =
          r
          |> Repo.delete()

        case re do
          {:ok, r} ->
            json(conn, %{data: %{}, success: true})

          _ ->
            json(conn, %{data: %{}, success: false, message: "Lỗi khi xoá data"})
        end
    end
  end
end
