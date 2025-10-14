defmodule HanaShirabe.Repo do
  use Ecto.Repo,
    otp_app: :hana_shirabe,
    adapter: Ecto.Adapters.SQLite3
end
