defmodule ExamWeb.ExamController do
  use ExamWeb, :controller
  import Plug.Conn
  import Ecto.Query, only: [from: 2]
  use Ecto.Repo, otp_app: :exam, adapter: Ecto.Adapters.Postgres

  plug(
    Exam.Plugs.Auth
    when action in [:index, :check_result, :change_user, :change_question, :get_intro]
  )

  alias Exam.Question
  alias Exam.User
  alias Exam.Result
  alias Exam.Exam

  def index(conn, parmas) do
    id_exam = parmas["id"]
    # IO.inspect(parmas)
    id_user = conn.assigns.user.user_id

    case id_exam do
      nil ->
        json(conn, %{data: %{}, status: "No id exam", success: false})

      _ ->
        re = ExamWeb.ResultController.create_default(id_exam, id_user, "exam")

        if re.success do
          data =
            get_exam(id_exam, false, id_user)
            |> Map.put("result", re.data)

          # IO.inspect(data)

          json(conn, %{data: data, success: true})
        else
          json(conn, %{data: %{}, status: "Error when create default", success: false})
        end
    end
  end

  def options(conn, params) do
    json(conn, %{})
  end

  def check_result(conn, parmas) do
    client_ans = parmas["ans"]
    id_exam = parmas["id_exam"]
    id_user = conn.assigns.user.user_id
    id_ref = parmas["id_ref"]
    source = parmas["source"] || "exam"
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

        # # IO.inspect(result)
        # save result

        current_result = Repo.get!(Result, id_ref)

        changeset =
          Result.changeset(current_result, %{
            "result" => result,
            "id_ref" => id_exam,
            "user_id" => id_user,
            "setting" => %{},
            "source" => source,
            "status" => "done"
          })

        result_t = Repo.update(changeset)
        # IO.inspect(result_t)
        json(conn, %{data: result, status: "ok", success: true})
    end
  end

  def change_user(conn, params) do
    id_user_list = params["user_do"]
    id_exam = params["id_exam"]
    id_user = conn.assigns.user.user_id
    # get exam
    data_exam = get_exam(id_exam, true, id_user)
    # check, not update when 1 day-offs
    # case

    case Map.has_key?(data_exam, :error) do
      true ->
        json(conn, %{data: %{}, status: "Exam isn't existed", success: false})

      false ->
        # new_user_do =
        #   Enum.filter(id_user_list ++ data_exam.data.list_user_do, fn x ->
        #     (!Enum.member?(id_user_list, x) && Enum.member?(data_exam.data.list_user_do, x)) or
        #       (!Enum.member?(data_exam.data.list_user_do, x) && Enum.member?(id_user_list, x))
        #   end)

        # # IO.inspect(new_user_do)
        # update
        exam = Repo.get!(Exam, id_exam)
        exam = Ecto.Changeset.change(exam, list_user_do: id_user_list)

        case Repo.update(exam) do
          {:ok, struct} ->
            # IO.inspect(struct)

            da =
              struct
              |> Map.drop([:__meta__])
              |> Poison.encode()

            case da do
              {:ok, data} -> json(conn, %{data: data, status: "ok", success: true})
              _ -> json(conn, %{data: da, status: "ok", success: false})
            end

          _ ->
            json(conn, %{data: %{}, status: "update fail", success: false})
        end
    end
  end

  def change_question(conn, params) do
    id_questions = params["question"]
    id_exam = params["id_exam"]
    id_user = conn.assigns.user.user_id
    # get exam
    data_exam = get_exam(id_exam, true, id_user)
    # check, not update when 1 day-offs

    case Map.has_key?(data_exam, :error) do
      true ->
        json(conn, %{data: %{}, status: "Exam isn't existed", success: false})

      false ->
        list_id = Enum.map(data_exam.data.question, fn x -> x.id end)
        # IO.inspect(list_id)

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

  # @spec get_exam(any, any, any) :: %{
  #         :data => %{optional(:publish) => boolean},
  #         optional(:error) => true,
  #         optional(:status) => <<_::160>>,
  #         optional(:success) => boolean
  #       }
  # def get_exam_v2(id_exam, id_user) do

  #   exam =
  #     from(e in Exam,
  #       where: e.id == ^id_exam,
  #       preload: (question_d: q)
  #     )
  #     |> Repo.one()

  #   IO.inspect(exam)
  # end

  def get_intro(conn, parmas) do
    id_exam = parmas["id_exam"]

    id_user = conn.assigns.user.user_id

    exam =
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

    case exam do
      nil ->
        json(conn, %{success: false, data: %{}})

      e ->
        data =
          e
          |> Map.put(:question, length(e.question))

        if data.publish do
          json(conn, %{success: true, data: data})
        else
          if id_user in data.list_user_do do
            json(conn, %{success: true, data: data})
          else
            json(conn, %{success: false, data: %{}, status: "You cant do this exam"})
          end
        end
    end
  end

  def get_exam(id_exam, type_get, id_user) do
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
        # preload: [:question]
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

        question_data =
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

        question_data = Repo.all(question_query)

        data =
          Map.merge(data_exam, %{
            question: question_data
          })

        case data_exam.publish do
          true ->
            %{data: data}

          false ->
            if id_user in data_exam.list_user_do do
              %{data: data, success: true}
            else
              %{data: %{}, status: "You cant do the exam", success: false}
            end
        end
    end
  end
end
