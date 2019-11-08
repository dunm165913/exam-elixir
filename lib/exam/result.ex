defmodule Exam.Result do
  alias Exam.User
  alias Exam.Exam
  use ExamWeb, :model


  schema "results" do
    field :result, {:array, :map}
    # field :exam_id, :integer
    # field :user_id, :integer
    belongs_to :user, User
    belongs_to :exam, Exam        
    timestamps()
  end
  def changeset(result, attrs) do
    result
    |> cast(attrs, [:result, :exam_id, :user_id])
    |> validate_required([:result])
  end
end