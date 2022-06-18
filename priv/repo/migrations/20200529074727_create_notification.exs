defmodule Exam.Repo.Migrations.CreateBotification do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :data, :map
      add :from, :map
      add :to, :integer
      add :setting, :map
      add :status, :string
      add :media, :map
      add :actions, {:array, :map}
      timestamps()
    end
  end
end
