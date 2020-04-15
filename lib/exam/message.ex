defmodule Exam.Message do
  #   use Ecto.Schema
  #   import Ecto.Changeset
  alias Exam.User
  use ExamWeb, :model

  schema "messages" do
    field :message, :string
    field :id_ref, :string
    field :setting, :map
    field :source, :string
    field :user_info, :map
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :message,
      :id_ref,
      :setting,
      :source,
      :user_id
      # :user_info
    ])
    |> validate_required([
      :message,
      :id_ref,
      :setting,
      :source,
      :user_id
      # :user_info
    ])
  end
end
