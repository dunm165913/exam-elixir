defmodule Exam.Repo.Migrations.AlertResultIdRef do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE results ALTER COLUMN id_ref TYPE integer USING (id_ref::integer)"

  end
end
