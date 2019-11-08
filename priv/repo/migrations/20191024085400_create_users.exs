defmodule Exam.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :email, :string
      add :password, :string
      add :role, :string
      add :codeVerfity, :integer

      timestamps()
    end

  end
end
