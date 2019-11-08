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
      nil -> json(conn, %{data: %{}, status: "No id question", success: false})
      _ -> 
        question_query = from(q in Question, where: q.id == ^id_question, select: %{id: q.id, as: q.as, question: q.question, correct_ans: q.correct_ans})
        data = Repo.one(question_query)
        IO.inspect(data)
        case data do
          nil -> json(conn, %{data: %{}, status: "No question", success: false})
          _ -> 
          data = data |> Map.take([:id, :question, :as, :correct_ans])
          json(conn, %{data: %{question: data}, status: "ok", success: true})

        end
        
    end
  end

  def create(conn, params) do
    changeset= Question.changeset(%Question{}, %{
      as: ["1", "2", "3", "4"],
      correct_ans: "3",
      question: "what's result of '1+2'? "
    })
    access_token = params["access_token"]
    verfity_token = JsonWebToken.verify(access_token,  %{key: "gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr9C"})
    IO.inspect(verfity_token)
    case verfity_token do
      {:ok, data} -> 
        data_question=%{
          as: ["1", "2", "3", "4"],
          correct_ans: "3",
          question: "what's result of '3*1'? ",
          user_id: data.user_id
        } 
        IO.inspect(data_question)
        changeset= Question.changeset(%Question{}, data_question)
        result = Repo.insert(changeset)
        IO.inspect(result)
        case result do
          {:error, changeset} -> json(conn, %{data: %{}, status: "Check your information", success: false})
          {:ok, _} -> json(conn, %{data: %{}, status: "ok", success: true})
            
        end

      {:error, _} -> json(conn, %{data: %{}, status: "token is invalid", success: false})
        
    end
        
  end
end