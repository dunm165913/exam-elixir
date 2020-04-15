defmodule ExamWeb.Cache do
  use GenServer
  import Plug.Conn
  alias :ets, as: Ets

  # thời gian sống của 1 entry mặc định là 6 phút
  @expired_after 90

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def set(key, value) do
    GenServer.cast(__MODULE__, {:set, key, value})
  end

  def set(key, value, ttl) do
    GenServer.cast(__MODULE__, {:set, key, value, ttl})
  end

  def get(key) do
    rs = Ets.lookup(:simple_cache, key) |> List.first()

    if rs == nil do
      {:error, :not_found}
    else
      expired_at = elem(rs, 2)

      cond do
        NaiveDateTime.diff(NaiveDateTime.utc_now(), expired_at) > 0 ->
          {:error, :expired}

        true ->
          {:ok, elem(rs, 1)}
      end
    end
  end

  def delete(key) do
    GenServer.cast(__MODULE__, {:delete, key})
  end

  def init(state) do
    Ets.new(:simple_cache, [:set, :protected, :named_table, read_concurrency: true])
    {:ok, state}
  end

  def handle_cast({:set, key, val, ttl}, state) do
    inserted_at =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(ttl, :second)

    Ets.insert(:simple_cache, {key, val, inserted_at})
    {:noreply, state}
  end
end
