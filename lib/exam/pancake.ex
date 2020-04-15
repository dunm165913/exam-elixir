defmodule Exam.Pancake do
  use ExamWeb, :model
  alias Exam.User

  schema "pancake" do
    field(:data, :map)
    field(:body, :map)
    field(:url, :string)
    field(:type, :string)
    timestamps()
  end

  @doc false
  def changeset(media, attrs) do
    media
    |> cast(attrs, [:data, :type, :url, :body])
    |> validate_required([:data, :type, :url, :body])
  end
end
