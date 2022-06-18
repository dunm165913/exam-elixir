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
    field :question, {:array, :string}
    field :detail, :string
    field :setting, :map
    field :type_exam, :string
    field :status, :string
    belongs_to :user, User

    timestamps()
  end

  @spec changeset(
          {map, map} | %{:__struct__ => atom | %{__changeset__: map}, optional(atom) => any},
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
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
      :type_exam,
      :status
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
