# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :exam,
  ecto_repos: [Exam.Repo]

# Configures the endpoint
config :exam, ExamWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "EHJUaEftiPO81s96IaYAM9Sk81YrbQ/vRAPZvx1nm+ZVXv/fBNNOY2sXWqshzX09",
  render_errors: [view: ExamWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: ExamWeb.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

# config :hello_phoenix,
#        mailgun_domain: "https://api.mailgun.net/v3/sandbox56f8d7aba4b54b8c97644bb80e0568bb.mailgun.org",
#        mailgun_key: "b8d8f538567771e5195c52aba2a1116e-816b23ef-57fb10fd"


# cloudinary
# config :ex_cloudinary,
#       cloud_name: "dunguyen",
#       api_key: "384762415366912",
#       api_secret: "BqcHoIOoc0f9SrNfbauhN3hIj4k"

config :cloudex,
  api_key: "384762415366912",
  secret: "BqcHoIOoc0f9SrNfbauhN3hIj4k",
  cloud_name: "dunguyen"
