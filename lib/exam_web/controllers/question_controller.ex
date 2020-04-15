defmodule ExamWeb.QuestionController do
  alias ExamWeb.{Tool}
  use ExamWeb, :controller
  import Plug.Conn
  import Ecto.Query, only: [from: 2]
  use Ecto.Repo, otp_app: :exam, adapter: Ecto.Adapters.Postgres

  alias Exam.Question

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
    q =
      from(Question,
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
          %{success: false, data: %{}, status: "Error when get DB"}
      end

    # IO.inspect(data)
    json(conn, data)
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
          json(conn, %{data: %{result: true}, status: "ok", success: true})
        else
          json(conn, %{data: %{result: false}, status: "ok", success: true})
        end
    end
  end

  def create(conn, params) do
    changeset =
      Question.changeset(%Question{}, %{
        as: ["1", "2", "3", "4"],
        correct_ans: "3",
        question: "what's result of '1+2'? "
      })

    access_token = params["access_token"]
    verfity_token = JsonWebToken.verify(access_token, %{key: "gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr9C"})
    # IO.inspect(verfity_token)

    case verfity_token do
      {:ok, data} ->
        data_question = %{
          as: ["1", "2", "3", "4"],
          correct_ans: "3",
          question: "what's result of '3*1'? ",
          user_id: data.user_id
        }

        # IO.inspect(data_question)
        changeset = Question.changeset(%Question{}, data_question)
        result = Repo.insert(changeset)
        # IO.inspect(result)

        case result do
          {:error, changeset} ->
            json(conn, %{data: %{}, status: "Check your information", success: false})

          {:ok, _} ->
            json(conn, %{data: %{}, status: "ok", success: true})
        end

      {:error, _} ->
        json(conn, %{data: %{}, status: "token is invalid", success: false})
    end
  end

  def get_question(id_question) do
    case id_question do
      nil ->
        nil

      _ ->
        question =
          from(q in Question, where: q.id == ^id_question, select: q)
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
        where: q.class == ^clas and q.subject == ^sub,
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
end
