defmodule Exam.ReviewQuestion do
    alias Exam.User
    alias Exam.Exam
    use ExamWeb, :model

    schema "review_question" do
      field :id_ref, :string
      field :data, :map
      belongs_to(:user, User)
      timestamps()
    end

    def changeset(result, attrs) do
      result
      |> cast(attrs, [:id_ref, :data, :user_id])
      |> validate_required([:id_ref, :data, :user_id])
    end
  end
