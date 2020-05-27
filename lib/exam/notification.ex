defmodule Exam.Notification do
  #   use Ecto.Schema
  #   import Ecto.Changeset
  alias Exam.User
  use ExamWeb, :model

  schema "notifications" do
    field :data, :map
    field :media, :map
    field :from, :map
    field :to, :string
    field :actions, {:array, :map}
    field :setting, :map
    field :status, :string
    timestamps()
  end

  @spec changeset(
          {map, map} | %{:__struct__ => atom | %{__changeset__: map}, optional(atom) => any},
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(n, attrs) do
    n
    |> cast(attrs, [
      :data,
      :media,
      :from,
      :to,
      :actions,
      :setting,
      :status
    ])
    |> validate_required([
      :data,
      :media,
      :from,
      :to,
      :actions,
      :setting,
      :status
    ])
  end
end
