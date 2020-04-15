defmodule Exam.Repo.Migrations.CreateResult do
  use Ecto.Migration

  def change do
    create table(:results) do
      add :user_id, references(:users)
      add :result, :map
      add :setting, :map
      add :source, :string
      add :id_ref, :string

      timestamps()
    end
  end
end
