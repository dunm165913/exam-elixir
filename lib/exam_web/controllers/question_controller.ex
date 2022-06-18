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
        data = Repo.get(Question, id_question)

        case data do
          nil ->
            json(conn, %{data: %{}, status: "No question", success: false})

          data ->
            {:ok, d} =
              data
              |> Map.drop([:__meta__])
              |> Poison.encode()

            l =
              d
              |> Poison.decode!()

            json(conn, %{data: l, status: "ok", success: true})
        end
    end
  end

  def get_random_question(conn, parmas) do
    clas = parmas["clas"] || "all"
    level = parmas["level"] || "all"
    subject = parmas["subject"] || "all"
    id = parmas["id"] || nil

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
      case id do
        nil ->
          from(q in Question,
            where: q.class in ^clas and q.subject in ^subject and q.level in ^level,
            order_by: fragment("RANDOM()"),
            limit: 1
          )

        _ ->
          from(q in Question, where: q.id == ^id, limit: 1)
      end
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
    clas = params["clas"] || ["10", "11", "12"]
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

    m = ExamWeb.MarkSubject.get_data_mark(id_user, "12", subject)

    u = m.data

    if Map.has_key?(u, :mark) && u.mark > 8 do
      q =
        case status do
          "all" ->
            from(q in Question,
              left_join: r in Result,
              on: r.id_ref == q.id and r.user_id == ^id_user and r.source == "review_question",
              where:
                q.class in ^clas and q.subject == ^subject and
                  q.status == "inreview" and q.level in ^level,
              limit: 100,
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
                q.class in ^clas and q.subject == ^subject and
                  q.status == "done" and q.level in ^level,
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
                  q.class in ^clas and q.subject == ^subject and
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

      json(conn, %{success: true, data: q})
    else
      json(conn, %{data: u, success: false, message: "Không đủ điểm"})
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

  def get_q(c, s, l, a, f, id_user, st) do
    class =
      if c == "all" do
        ["10", "11", "12"]
      else
        [c]
      end

    subject =
      if s == "all" do
        ["T", "L", "H"]
      else
        [s]
      end

    level =
      if l == "all" do
        ["1", "2", "2"]
      else
        [l]
      end

    st =
      if st == "all" do
        ["done", "review", "inreview"]
      else
        [st]
      end

    query =
      case a do
        nil ->
          case f do
            "all" ->
              from(q in Question,
                where:
                  q.class in ^class and q.subject in ^subject and q.level in ^level and
                    q.status in ^st,
                select: q,
                limit: 30,
                order_by: [desc: :id]
              )

            _ ->
              from(q in Question,
                where:
                  q.class in ^class and q.subject in ^subject and q.level in ^level and
                    q.user_id == ^id_user and q.status in ^st,
                select: q,
                limit: 30,
                order_by: [desc: :id]
              )
          end

        _ ->
          case f do
            "all" ->
              from(q in Question,
                where:
                  q.class in ^class and q.subject in ^subject and q.level in ^level and
                    q.status in ^st,
                group_by: q.id,
                having: q.id < ^a,
                select: q,
                limit: 30,
                order_by: [desc: :id]
              )

            _ ->
              from(q in Question,
                where:
                  q.class in ^class and q.subject in ^subject and q.level in ^level and
                    q.user_id == ^id_user and q.status in ^st,
                group_by: q.id,
                having: q.id < ^a,
                select: q,
                limit: 30,
                order_by: [desc: :id]
              )
          end
      end
      |> Repo.all()
      |> Enum.map(fn d ->
        {:ok, f} =
          d
          |> Map.drop([:__meta__])
          |> Poison.encode()

        f
        |> Poison.decode!()
      end)
  end

  def get_question(conn, parmas) do
    id_user = conn.assigns.user.user_id
    class = parmas["clas"] || "all"
    subject = parmas["subject"] || "all"
    level = parmas["level"] || "all"
    afterQ = parmas["after"] || nil
    from = parmas["from"] || "all"
    status = parmas["status"] || "done"
    id = parmas["id"] || nil
    my_q = parmas["my_question"] || "false"

    data =
      case id do
        nil ->
          get_q(class, subject, level, afterQ, from, id_user, status)

        _ ->
          case my_q do
            "false" ->
              from(q in Question,
                where: q.id == ^id and q.status == "done",
                select: q
              )
              |> Repo.all()
              |> Enum.map(fn d ->
                {:ok, f} =
                  d
                  |> Map.drop([:__meta__])
                  |> Poison.encode()

                f
                |> Poison.decode!()
                |> Map.merge(%{correct_ans: nil})
              end)

            _ ->
              from(q in Question,
                where: q.id == ^id and q.user_id == ^id_user,
                select: q
              )
              |> Repo.all()
              |> Enum.map(fn d ->
                {:ok, f} =
                  d
                  |> Map.drop([:__meta__])
                  |> Poison.encode()

                f
                |> Poison.decode!()
              end)
          end
      end

    json(conn, %{data: data, success: true})
  end

  def get_q_by_user_and_id(id, u) do
    q =
      from(q in Question, where: q.id == ^id and q.user_id == ^u)
      |> Repo.one()

    case q do
      nil ->
        %{success: false, data: %{}, message: "Not found question"}

      _ ->
        %{success: true, data: q}
    end
  end

  def update_question(conn, p) do
    id_user = conn.assigns.user.user_id
    id_q = p["data"]["id"]

    #  get q
    q = get_q_by_user_and_id(id_q, id_user)

    if q.success do
      case q.data.status do
        "done" ->
          json(conn, %{
            data: %{},
            success: false,
            message: "Không thể cập nhật câu hỏi khi đã publish"
          })

        "inreview" ->
          json(conn, %{
            data: %{},
            success: false,
            message: "Không thể cập nhật câu hỏi khi đang review"
          })

        "review" ->
          result =
            Question.changeset(q.data, p["data"])
            |> Repo.update()

          case result do
            {:ok, f} ->
              json(conn, %{data: %{}, success: true})

            {:error, g} ->
              IO.inspect(g)
              json(conn, %{data: %{}, success: false, message: "Cập nhật thất bại"})
          end
      end
    else
      json(conn, q)
    end
  end

  def update_q_by_admin(conn, p) do
    id_user = conn.assigns.user.user_id
    id_q = p["data"]["id"]
    token = p["access_token"]
    u = ExamWeb.UserController.check_is_admin(token)

    if u.success do
      q = Repo.get(Question, id_q)

      case q do
        nil ->
          %{success: false, data: %{}, message: "Not found question"}

        _ ->
          result =
            Question.changeset(q, p["data"])
            |> Repo.update()

          case result do
            {:ok, f} ->
              json(conn, %{data: %{}, success: true})

            {:error, g} ->
              IO.inspect(g)
              json(conn, %{data: %{}, success: false, message: "Cập nhật thất bại"})
          end
      end
    else
      json(conn, %{data: %{}, success: false, message: "Not admin"})
    end
  end

  def get_list_by_admin(conn, p) do
    id_user = p["id_user"] || nil
    class = p["clas"] || "all"
    subject = p["subject"] || "all"
    level = p["level"] || "all"
    afterQ = p["after"] || nil
    from = p["from"] || "all"
    status = p["status"] || "done"
    id = p["id"] || nil
    my_q = p["my_question"] || "false"

    is_admin = ExamWeb.UserController.check_is_admin(p["access_token"] || "")

    IO.inspect(is_admin)

    if is_admin.success do
      data =
        if id == nil do
          get_q(class, subject, level, afterQ, from, id_user, status)
        else
          question = Repo.get(Question, id)

          data =
            question
            |> Map.drop([:__meta__])
            |> Poison.encode()

          case data do
            {:ok, q} ->
              da =
                q
                |> Poison.decode!()

              [da]

            _ ->
              []
          end
        end

      json(conn, %{data: data, success: true})
    else
      json(conn, %{data: %{}, success: false, message: "Not admin"})
    end
  end

  def get_submit_question_by_admin(conn, p) do
    is_admin = ExamWeb.UserController.check_is_admin(p["access_token"] || "")

    if is_admin.success do
      id_q = p["id"]
      data = ExamWeb.ResultController.get_submit_question(id_q)

      json(conn, %{data: data, success: true})
    else
      json(conn, %{data: %{}, success: false, message: "Not admin"})
    end
  end

  def admin_update(conn, p) do
    id = p["id"]
    status = p["status"] || "done"

    # get _q
    is_admin = ExamWeb.UserController.check_is_admin(p["access_token"])

    if is_admin.success do
      q =
        from(q in Question, where: q.id == ^id and q.status == "review", limit: 1)
        |> Repo.one()

      case q.status do
        "review" ->
          changeset =
            Question.changeset(q, %{
              "status" => "inreview"
            })
            |> Repo.update()

          case changeset do
            {:ok, f} ->
              IO.inspect(f)
              # send notification to user who is owner question
              GenServer.cast(
                ExamWeb.Notification,
                {:change_status_question,
                 %{
                   "actions" => [],
                   "setting" => %{},
                   "to" => q.user_id,
                   "media" => %{},
                   "data" => %{"message" => "Câu hỏi #{id} đang đươc review"},
                   "from" => %{"source" => "Hệ thống  Exam", "question" => id}
                 }}
              )

              json(conn, %{data: %{}, success: true})

            {:error, g} ->
              IO.inspect(g)
              json(conn, %{data: %{}, message: "Check your info", success: false})
          end

        "inreview" ->
          # update question to system
          json(conn, %{
            data: %{},
            message: "Hệ thống đang thử nghiêm tính năng này",
            success: false
          })

        _ ->
          json(conn, %{data: %{}, success: false, message: "Trạng thái câu hỏi không hợp lệ "})
      end
    else
      json(conn, %{data: %{}, success: false, message: "Not admin"})
    end
  end

  def admin_eject(conn, p) do
    id = p["id"]
    reson = p["message"]

    is_admin = ExamWeb.UserController.check_is_admin(p["access_token"])

    if is_admin.success do
      q =
        from(q in Question, where: q.id == ^id and q.status in ["review", "inreview"], limit: 1)
        |> Repo.one()

      case q do
        nil ->
          json(conn, %{success: false, message: "Not found question"})

        _ ->
          changeset =
            Question.changeset(q, %{
              "result_review" =>
                (q.result_review || []) ++
                  [
                    %{
                      success: false,
                      message: reson
                    }
                  ],
              "status" => "review"
            })
            |> Repo.update()

          case changeset do
            {:ok, f} ->
              IO.inspect(f)
              # send notification to user who is owner question
              GenServer.cast(
                ExamWeb.Notification,
                {:change_status_question,
                 %{
                   "actions" => [],
                   "setting" => %{},
                   "to" => q.user_id,
                   "media" => %{},
                   "data" => %{"message" => "Câu hỏi #{id} bị từ chối vì:  #{reson}"},
                   "from" => %{"source" => "Hệ thống Exam", "question" => id}
                 }}
              )

              json(conn, %{data: %{}, success: true})

            {:error, g} ->
              IO.inspect(g)
              json(conn, %{data: %{}, message: "Check your info", success: false})
          end
      end
    else
      json(conn, %{data: %{}, success: false, message: "Not admin"})
    end
  end

  def submit_by_admin(conn, p) do
    id = p["id"]
    reson = p["message"]

    is_admin = ExamWeb.UserController.check_is_admin(p["access_token"])

    if is_admin.success do
      q =
        from(q in Question, where: q.id == ^id and q.status == "inreview", limit: 1)
        |> Repo.one()

      case q do
        nil ->
          json(conn, %{success: false, message: "Not found"})

        _ ->
          changeset =
            Question.changeset(q, %{
              "status" => "done"
            })
            |> Repo.update()

          case changeset do
            {:ok, f} ->
              IO.inspect(f)
              # send notification to user who is owner question
              GenServer.cast(
                ExamWeb.Notification,
                {:change_status_question,
                 %{
                   "actions" => [],
                   "setting" => %{},
                   "to" => q.user_id,
                   "media" => %{},
                   "data" => %{"message" => "Câu hỏi #{id} đã có mặt trên hệ thống"},
                   "from" => %{"source" => "Hệ thống Exam", "question" => id}
                 }}
              )

              # caculator all submitions of question
              GenServer.cast(
                ExamWeb.Process,
                {:caculator_mark_after_submit_question, %{"id" => id}}
              )

              json(conn, %{data: %{}, success: true})

            {:error, g} ->
              IO.inspect(g)
              json(conn, %{data: %{}, message: "Check your info", success: false})
          end
      end
    else
      json(conn, %{data: %{}, success: false, message: "Not admin"})
    end
  end

  def caculator_mark_after_submit_question(p) do
    id = p["id"]

    q = Repo.get(Question, id)

    {:ok, d} =
      q
      |> Map.drop([:__meta__])
      |> Poison.encode()

    data_q =
      d
      |> Poison.decode!()

    IO.inspect(data_q)

    all_result =
      from(r in Result, where: r.id_ref == ^id and r.source == "review_question")
      |> Repo.all()
      |> Enum.map(fn re ->
        result_current = Enum.at(re.result, 0)
        your_ans = result_current["your_ans"]

        if your_ans == data_q["correct_ans"] do
          changeset =
            Result.changeset(re, %{
              "result" => [Map.merge(result_current, %{"result" => true})],
              "status" => "done"
            })
            |> Repo.update()

          ExamWeb.MarkSubject.create_mark_by_question(
            re.user_id,
            id,
            true,
            "review_question",
            re.id
          )

          # caculator mark_subject
        else
          changeset =
            Result.changeset(re, %{
              "result" => [Map.merge(result_current["your_ans"], %{"result" => false})]
            })
            |> Repo.update()

          # ExamWeb.MarkSubject.create_mark_by_question(
          #   re.user_id,
          #   id,
          #   false,
          #   "review_question",
          #   re.id
          # )
        end
      end)
  end
end
