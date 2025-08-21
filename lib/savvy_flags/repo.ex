defmodule SavvyFlags.Repo do
  use Ecto.Repo,
    otp_app: :savvy_flags,
    adapter: Ecto.Adapters.Postgres
end
