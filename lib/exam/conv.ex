defmodule Exam.Conv do
  defmodule Exam.Exam do
  #   use Ecto.Schema
  #   import Ecto.Changeset
  alias Exam.User
  alias Exam.Question
  use ExamWeb, :model

  schema "exams" do
    field :name, :string


    timestamps()
  end

  @doc false
  def changeset(e, attrs) do
    e
    |> cast(attrs, [
      :subject,

    ])
    |> validate_required([
      :subject,
    ])
  end
end

end
