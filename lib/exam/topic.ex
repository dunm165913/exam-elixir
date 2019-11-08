defmodule Exam.Topic do
    alias Exam.User
    alias Exam.Exam
    use ExamWeb, :model
  
    schema "results" do
      field :name, :string
      field :url_media, {:array, :string}
      field :detail, :string
      field :history, {:array, :map}
      field :extra_option, :map
      belongs_to(:user, User)
      has_many(:exam, Exam)
      timestamps()
    end
  
    def changeset(result, attrs) do
      result
      |> cast(attrs, [:result, :exam_id, :user_id])
      |> validate_required([:result])
    end
  end