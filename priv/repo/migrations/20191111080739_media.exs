defmodule Exam.Repo.Migrations.Media do
  use Ecto.Migration

  def change do
    create table(:media) do
      add :user_id, references(:users)
      add :publish_id, :string
      add :secure_url, :string

      timestamps()
    end
  end
end
