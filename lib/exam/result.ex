defmodule Exam.Result do
  alias Exam.User
  alias Exam.Exam
  use ExamWeb, :model

  schema "results" do
    field :result, {:array, :map}
    field :source, :string
    field :setting, :map
    field :id_ref, :string
    # field :exam_id, :integer
    # field :user_id, :integer
    field :status, :string
    belongs_to :user, User
    timestamps()
  end

  def changeset(result, attrs) do
    result
    |> cast(attrs, [:result, :source, :setting, :id_ref, :user_id, :status])
    |> validate_required([:result, :source, :setting, :id_ref, :user_id, :status])
  end
end
