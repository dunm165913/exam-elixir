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
    field :list_user_do, {:array, :integer}, default: []
    field :question, {:array, :integer}
    field :detail, :string
    field :setting, :map
    field :type_exam, :string
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(e, attrs) do
    e
    |> cast(attrs, [
      :subject,
      :class,
      # :time,
      :start,
      # :number_students,
      :publish,
      :question,
      :list_user_do,
      :user_id,
      :setting,
      :type_exam
    ])
    |> validate_required([
      :subject,
      :class,
      # :time,
      :start,
      # :number_students,
      :publish,
      :question,
      :list_user_do,
      :user_id,
      :setting,
      :type_exam
    ])
  end
end
