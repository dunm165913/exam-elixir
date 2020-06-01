defmodule Exam.Repo.Migrations.CreateQuestion do
  use Ecto.Migration

  def change do
      create table(:questions) do
      add :as, {:array,"text"}, default: []
      add :correct_ans, :string
      add :question, :string
      add :parent_question, :string
      add :type, :string
      add :subject, :string
      add :level, :string
      add :class, :string
      add :detail, :string
      add :url_media, :string
      add :history, {:array, :map}
      add :user_id, references(:users)

      timestamps()
    end
  end
end
