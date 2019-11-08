defmodule ExamWeb.ExamController do
  use ExamWeb, :controller
  import Plug.Conn
  import Ecto.Query, only: [from: 2]
  use Ecto.Repo, otp_app: :exam, adapter: Ecto.Adapters.Postgres
  plug(Exam.Plugs.Auth when action in [:index, :check_result, :change_user, :change_question])
  alias Exam.Question
  alias Exam.User
  alias Exam.Result
  alias Exam.Exam

  def index(conn, parmas) do
    id_exam = parmas["id"]
    IO.inspect(conn.assigns.user.user_id)
    id_user = conn.assigns.user.user_id

    case id_exam do
      nil ->
        json(conn, %{data: %{}, status: "No id exam", success: false})

      _ ->
        data = get_exam(id_exam, false, id_user)
        json(conn, data)
    end
  end

  def check_result(conn, parmas) do
    client_ans = parmas["ans"]
    id_exam = parmas["id_exam"]
    id_user = conn.assigns.user.user_id
    data = get_exam(id_exam, true, id_user)

    case Map.has_key?(data, :error) do
      true ->
        json(conn, %{data: %{}, status: "Exam isn't existed", success: false})

      false ->
        result =
          Enum.reduce(data.data.question, [], fn d, acc ->
            if d.correct_ans == client_ans["#{d.id}"] do
              acc ++
                [
                  %{
                    id: d.id,
                    result: true,
                    your_ans: client_ans["#{d.id}"]
                  }
                ]
            else
              acc ++
                [
                  %{
                    id: d.id,
                    result: false,
                    your_ans: client_ans["#{d.id}"]
                  }
                ]
            end
          end)

        # IO.inspect(result)
        # save result

        changeset =
          Result.changeset(%Result{}, %{
            "result" => result,
            "exam_id" => id_exam,
            "user_id" => id_user
          })

        result_t = Repo.insert(changeset)
        IO.inspect(result_t)
        json(conn, %{data: result, status: "ok", success: true})
    end
  end

  def change_user(conn, params) do
    id_user_list = params["user_do"]
    id_exam = params["id_exam"]
    id_user = conn.assigns.user.user_id
    # get exam
    data_exam = get_exam(id_exam, true, id_user)
     #check, not update when 1 day-offs
    # case 

    case Map.has_key?(data_exam, :error) do
      true ->
        json(conn, %{data: %{}, status: "Exam isn't existed", success: false})

      false ->
        new_user_do =
          Enum.filter(id_user_list ++ data_exam.data.list_user_do, fn x ->
            (!Enum.member?(id_user_list, x) && Enum.member?(data_exam.data.list_user_do, x)) or
              (!Enum.member?(data_exam.data.list_user_do, x) && Enum.member?(id_user_list, x))
          end)

        IO.inspect(new_user_do)
        # update
        exam = Repo.get!(Exam, id_exam)
        exam = Ecto.Changeset.change(exam, list_user_do: new_user_do)

        case Repo.update(exam) do
          {:ok, struct} -> json(conn, %{data: %{}, status: "ok", success: true})
          _ -> json(conn, %{data: %{}, status: "update fail", success: false})
        end
    end
  end

  def change_question(conn, params) do
    id_questions = params["question"]
    id_exam = params["id_exam"]
    id_user = conn.assigns.user.user_id
    # get exam
    data_exam = get_exam(id_exam, true, id_user)
    #check, not update when 1 day-offs

    case Map.has_key?(data_exam, :error) do
      true ->
        json(conn, %{data: %{}, status: "Exam isn't existed", success: false})

      false ->
        list_id = Enum.map(data_exam.data.question, fn x -> x.id end)
        IO.inspect(list_id)
        new_question =
          Enum.filter(list_id ++ id_questions, fn x ->
            (!Enum.member?(id_questions, x) && Enum.member?(list_id, x)) or
              (!Enum.member?(list_id, x) && Enum.member?(id_questions, x))
          end)

        # update
        exam = Repo.get!(Exam, id_exam)
        exam = Ecto.Changeset.change(exam, question: new_question)

        case Repo.update(exam) do
          {:ok, struct} -> json(conn, %{data: %{}, status: "ok", success: true})
          _ -> json(conn, %{data: %{}, status: "update fail", success: false})
        end
    end
  end

  defp get_exam(id_exam, type_get, id_user) do
    exam_query =
      from(e in Exam,
        where: e.id == ^id_exam,
        select: %{
          id: e.id,
          class: e.class,
          subject: e.subject,
          time: e.time,
          start: e.start,
          question: e.question,
          list_user_do: e.list_user_do,
          number_students: e.number_students,
          publish: e.publish
        }
      )
      |> Repo.one()

    case exam_query do
      nil ->
        %{data: %{}, status: "ID exam is incorrect", error: true, success: false}

      _ ->
        data_exam =
          Map.take(exam_query, [
            :id,
            :class,
            :subject,
            :time,
            :start,
            :question,
            :list_user_do,
            :number_students,
            :publish
          ])

        question_query =
          from(q in Question,
            where: q.id in ^data_exam.question,
            select: %{
              parent_question: q.parent_question,
              id: q.id,
              question: q.question,
              url_media: q.url_media,
              level: q.level,
              type: q.type,
              as: q.as
            }
          )

        question_query =
          if type_get do
            from(q in question_query, select_merge: %{correct_ans: q.correct_ans})
          else
            question_query
          end

        IO.inspect(question_query)
        question_data = Repo.all(question_query)
        IO.inspect(question_data)

        data =
          Map.merge(data_exam, %{
            question: question_data
          })

        case data_exam.publish do
          true ->
            %{data: data}

          false ->
            user_query =
              from(u in User,
                where: u.id in ^data_exam.list_user_do,
                select: %{
                  id: u.id
                }
              )
              |> Repo.all()
              |> Enum.map(fn data -> data.id end)

            if id_user in user_query do
              %{data: data, success: true}
            else
              %{data: %{}, status: "You cant do the exam", success: false}
            end
        end
    end
  end
end