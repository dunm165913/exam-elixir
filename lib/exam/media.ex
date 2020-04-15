defmodule Exam.Media do
  use ExamWeb, :model
  alias Exam.User

  schema "media" do
    field(:publish_id, :string)
    field(:secure_url, :string)

    belongs_to(:user, User)

    timestamps()
  end

  @doc false
  def changeset(media, attrs) do
    media
    |> cast(attrs, [:publish_id, :secure_url])
    |> validate_required([:publish_id, :secure_url, :user_id])
  end
end