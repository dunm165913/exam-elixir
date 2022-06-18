defmodule Exam.Repo.Migrations.AddTableNews do
  use Ecto.Migration

  def change do
    create table(:news) do
      add :data, :string
      add :id_ref, :string
      add :user_id, references(:users)
      add :setting, :map
      add :source, :string
      timestamps()
    end
  end
end
