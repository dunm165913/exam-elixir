defmodule Exam.Repo.Migrations.Pancake do
  use Ecto.Migration

  def change do
    create table(:pancake) do
      add :data, :map
      add :type, :string
      timestamps()
    end
  end
end
