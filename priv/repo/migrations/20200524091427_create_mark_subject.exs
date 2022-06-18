defmodule Exam.Repo.Migrations.CreateMarkSubject do
  use Ecto.Migration

  def change do
    create table("mark_subject") do
      add :mark, :float
      add :number, :integer
      add :number_correct, :integer
      add :current_data, :map
      add :subject, :map
      add :class, :map
     add :id_ref, :string
     add :source, :string
      add :user_id, references(:users)
      timestamps()
    end
  end
end
