defmodule ExamWeb.UserPresence do
  use Phoenix.Presence,
    otp_app: :exam,
    pubsub_server: Phoenix.PubSub
end
