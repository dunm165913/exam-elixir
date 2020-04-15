defmodule ExamWeb.PancakeController do
  alias ExamWeb.{Tool}
  use ExamWeb, :controller
  import Plug.Conn
  import Ecto.Query, only: [from: 2]
  use Ecto.Repo, otp_app: :exam, adapter: Ecto.Adapters.Postgres

  alias Exam.Pancake

  def create(conn, params) do
    data = params["data"]
    # IO.inspect(data)

    # conver = data["conver"]
    # selectedId = conver["selectedId"]

    # url = data["url"]

    # convId = data["navigation"]["params"]["data"]["convId"]

    changeset =
      Pancake.changeset(%Pancake{}, %{
        data: params["data"],
        url: params["data"]["url"],
        body: params["data"]["body"],
        type: "false"
      })

    result = Repo.insert(changeset)
    # IO.inspect(result)

    case result do
      {:error, changeset} -> json(conn, %{})
      {:ok, _} -> json(conn, %{})
    end
  end

  def get_mesage(mes) do
    # question_query = from(p in Pancake, select: %{data: p.data})
    re = []

    data =
      Repo.all(Pancake)
      |> Enum.map(fn x ->
        body = x.data["body"]
        message = body

        if String.match?(message, ~r/#{mes}/) do
          re = re ++ [x]
        end
      end)

    # IO.inspect(re)
  end
end
