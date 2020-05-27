defmodule Exam.MarkSubject do
    alias Exam.User
    alias Exam.Exam
    use ExamWeb, :model

    schema "mark_subject" do
      field :mark, :float
      field :number, :integer
      field :number_correct, :integer
      field :current_data, :map
      field :subject, :string
      field :class, :string
      field :id_ref, :string
      field :source, :string


      belongs_to(:user, User)
      timestamps()
    end

    def changeset(m, attrs) do
      m
      |> cast(attrs, [:mark, :number, :number_correct, :current_data, :user_id, :subject, :class, :source, :id_ref])
      |> validate_required([:mark, :number, :number_correct, :current_data, :user_id, :subject, :class, :source, :id_ref])
    end
  end
