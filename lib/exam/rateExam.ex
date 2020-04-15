defmodule Exam.RateExam do
  #   use Ecto.Schema
  #   import Ecto.Changeset
  alias Exam.{User, Exam}
  use ExamWeb, :model

  schema "rateExams" do
    field :star, :string
    field :content, :string
    # field :user_id, :string
    # field :exam_id, :string
    belongs_to :user, User
    belongs_to :exam, Exam

    # field :user_id, :integer
    timestamps()
  end

  @doc false
  def changeset(rateExam, attrs) do
    rateExam
    |> cast(attrs, [
      :star,
      :content,
      :exam_id,
      :user_id
    ])
    |> validate_required([
      :star,
      :content,
      :exam_id,
      :user_id
    ])
  end
end
