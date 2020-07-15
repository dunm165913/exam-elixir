defmodule Exam.Repo.Migrations.AddNameConvFriend do
  use Ecto.Migration

  def change do
    create table(:friends) do
      add :per1, :integer
      add :per2, :integer
      add :conv, :string
      add :status, :string
      add :nick_name, {:array, :map}
      timestamps()
    end
  end
end
