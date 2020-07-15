defmodule ExamWeb.MarkSubject do
  use ExamWeb, :controller
  import Plug.Conn
  import Ecto.Query, only: [from: 2]
  use Ecto.Repo, otp_app: :exam, adapter: Ecto.Adapters.Postgres
  plug(Exam.Plugs.Auth)
  alias Exam.Question
  alias Exam.User
  alias Exam.ReviewQuestion
  alias Exam.MarkSubject

  def create(conn, params) do
    id_user = conn.assigns.user.user_id
    # id_ref is id_question
    id_ref = params["id_ref"]
    result = params["result"]

    # get question which has in review status and user who has mark ?

    # question
    data = create_mark_by_question(id_user, id_ref, result)
    json(conn, data)
  end

  @spec create_mark_by_question(any, any, any, any, any) :: %{
          :data => %{},
          :success => boolean | <<_::40>>,
          optional(:message) => <<_::136>>
        }
  def create_mark_by_question(
        id_user,
        id_question,
        result,
        source \\ "question",
        id_result \\ nil
      ) do
    q =
      from(q in Question,
        where: q.id == ^id_question,
        select: %{
          class: q.class,
          id: q.id,
          question: q.question,
          subject: q.subject,
          as: q.as,
          correct_ans: q.correct_ans
        }
      )
      |> Repo.one()

    case q do
      nil ->
        %{data: %{}, success: "false", message: "No question found"}

      _ ->
        # get current mark of user
        mark =
          from(m in MarkSubject,
            where: m.user_id == ^id_user and m.subject == ^q.subject,
            order_by: [desc: :id],
            limit: 1,
            select: %{
              mark: m.mark,
              number: m.number,
              number_correct: m.number_correct
            }
          )
          |> Repo.one()

        IO.inspect(mark)

        case mark do
          nil ->
            mark_q =
              if result do
                10
              else
                0
              end

            n_correct =
              if result do
                1
              else
                0
              end

            changeset =
              MarkSubject.changeset(%MarkSubject{}, %{
                "mark" => mark_q,
                "number" => 1,
                "number_correct" => n_correct,
                "current_data" => Map.merge(q, %{"result" => result, "id_result" => id_result}),
                "subject" => q.subject,
                "class" => "12",
                "user_id" => id_user,
                "id_ref" => "#{id_question}",
                "source" => source
              })

            case Repo.insert(changeset) do
              {:ok, d} ->
                %{data: %{}, success: true}

              {:error, s} ->
                IO.inspect(s)
                %{data: %{}, success: false}
            end

          _ ->
            IO.inspect(mark)

            mark_s =
              if result do
                10
              else
                0
              end

            n_correct =
              if result do
                1
              else
                0
              end

            mark_q = (mark.mark * mark.number + mark_s) / (mark.number + 1)
            mark_num_correct = mark.number_correct + n_correct
            mark_num = mark.number + 1

            IO.inspect(mark_num)
            IO.inspect(mark_num_correct)
            IO.inspect(mark_q)

            changeset =
              MarkSubject.changeset(%MarkSubject{}, %{
                "mark" => mark_q,
                "number" => mark_num,
                "number_correct" => mark_num_correct,
                "current_data" => Map.merge(q, %{"result" => result, "id_result" => id_result}),
                "subject" => q.subject,
                "class" => "12",
                "user_id" => id_user,
                "id_ref" => "#{id_question}",
                "source" => source
              })
              |> Repo.insert()

            case changeset do
              {:ok, s} ->
                %{data: %{}, success: true}

              {:error, c} ->
                IO.inspect(c)
                %{data: %{}, success: false}
            end
        end
    end
  end

  def create_mark_by_result_exam(
        id_user,
        id_exam,
        result,
        subject,
        class,
        id_ref,
        coefficient \\ 1
      ) do
    IO.inspect(id_user)
    IO.inspect(subject)
    IO.inspect(class)
    # get current Mark
    mark =
      from(m in MarkSubject,
        where: m.user_id == ^id_user and m.subject == ^subject,
        order_by: [desc: :id],
        limit: 1,
        select: %{
          mark: m.mark,
          number: m.number,
          number_correct: m.number_correct
        }
      )
      |> Repo.one()

    # IO.inspect(mark)
    mark =
      case mark do
        nil ->
          %{
            number: 0,
            number_correct: 0,
            mark: 0
          }

        _ ->
          mark
          # count numbercorrect
      end

    total_num = Enum.count(result) || 0

    total_num_correct =
      Enum.count(
        result
        |> Enum.filter(fn x ->
          x.result
        end)
      )

    new_total_num = (mark.number || 0) + total_num
    new_correct_num = (mark.number_correct || 0) + total_num_correct

    new_mark = (mark.mark * mark.number + coefficient * 10 * total_num_correct) / new_total_num

    changeset =
      MarkSubject.changeset(%MarkSubject{}, %{
        "mark" => new_mark,
        "number" => new_total_num,
        "number_correct" => new_correct_num,
        "current_data" => %{"id_result" => id_ref},
        "subject" => subject,
        "class" => "12",
        "user_id" => id_user,
        "id_ref" => "#{id_exam}",
        "source" => "exam"
      })
      |> Repo.insert()

    case changeset do
      {:ok, s} ->
        %{data: %{}, success: true}

      {:error, c} ->
        IO.inspect(c)
        %{data: %{}, success: false}
    end
  end

  def get_mark(conn, params) do
    # default class = 12
    clas = "12"
    id_user = conn.assigns.user.user_id
    subject = params["subject"]

    data = get_data_mark(id_user, clas, subject)
    json(conn, data)
  end

  @spec get_data_mark(any, any, any) :: %{
          :data => any,
          optional(:message) => <<_::56>>,
          optional(:status) => false,
          optional(:success) => true
        }
  def get_data_mark(id_user, clas, subject) do
    mark =
      from(m in MarkSubject,
        where: m.user_id == ^id_user and m.subject == ^subject and m.class == ^clas,
        order_by: [desc: :id],
        limit: 1,
        select: %{
          mark: m.mark,
          number: m.number,
          number_correct: m.number_correct,
          at: m.inserted_at
        }
      )
      |> Repo.one()

    case mark do
      nil -> %{data: %{}, status: false, message: "No data"}
      _ -> %{data: mark, success: true}
    end
  end

  def get_data_mark_all(id_user, subject, class, s, e) do
    mark =
      from(m in MarkSubject,
        where:
          m.user_id == ^id_user and m.subject == ^subject and m.class == ^class and
            m.inserted_at < ^e and m.inserted_at > ^s,
        order_by: [desc: :id],
        select: %{
          mark: m.mark,
          number: m.number,
          number_correct: m.number_correct,
          source: m.source,
          at: m.inserted_at
        }
      )
      |> Repo.all()

    case mark do
      nil -> %{data: %{}, status: false, message: "No data"}
      _ -> %{data: mark, success: true}
    end
  end

  def get_mark_subject(conn, params) do
    id_user = conn.assigns.user.user_id
    subject = params["subject"]
    s = params["start"]
    e = params["end"]

    data = get_data_mark_all(id_user, subject, "12", s, e)
    json(conn, data)
  end

  def get_statistic_by_admin(conn, p) do
    token = p["access_token"]
    is_admin = ExamWeb.UserController.check_is_admin(token)

    if is_admin.success do
      id_u = p["id"]

      t = get_data_mark(id_u, "12", "T")
      l = get_data_mark(id_u, "12", "L")
      h = get_data_mark(id_u, "12", "H")

      json(conn, %{
        data: %{t: t, l: l, h: h},
        success: true
      })
    else
      json(conn, %{data: %{}, success: false, message: "Not admin"})
    end
  end
end
