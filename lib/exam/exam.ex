defmodule Exam.Exam do
  #   use Ecto.Schema
  #   import Ecto.Changeset
  alias Exam.User
  alias Exam.Question
  use ExamWeb, :model

  schema "exams" do
    field :subject, :string
    field :class, :string
    field :time, :utc_datetime
    field :start, :utc_datetime
    field :number_students, :integer
    field :publish, :boolean
    field :list_user_do, {:array, :integer}
    field :question, {:array, :integer}
    field :detail, :string
    belongs_to :user, User
    has_many :question_data, :Question

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :subject,
      :class,
      :time,
      :start,
      :number_students,
      :publish,
      :question,
      :list_user_do,
      :user_id
    ])
    |> validate_required([
      :subject,
      :class,
      :time,
      :start,
      :number_students,
      :publish,
      :question,
      :list_user_do,
      :user_id
    ])
  end
end
