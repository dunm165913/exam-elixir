defmodule Exam.Repo.Migrations.CreateMessage do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :message, :string
      add :id_ref, :string
      add :user_id, references(:users)
      add :setting, :map
      add :source, :string
      add :user_info, :map
      timestamps()
    end
  end
end
