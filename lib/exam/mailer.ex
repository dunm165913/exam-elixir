defmodule Exam.Mailer do
    use Mailgun.Client,
        domain: "https://api.mailgun.net/v3/sandbox56f8d7aba4b54b8c97644bb80e0568bb.mailgun.org",
        key: "b8d8f538567771e5195c52aba2a1116e-816b23ef-57fb10fd"
    #     mailgun_domain: "https://api.mailgun.net/v3/sandbox56f8d7aba4b54b8c97644bb80e0568bb.mailgun.org",
    #    mailgun_key: "b8d8f538567771e5195c52aba2a1116e-816b23ef-57fb10fd"

    def send_welcome_text_email(email_address) do
        send_email to: email_address,
                   from: "dunguyen20091998@gmail.com",
                   subject: "Welcome!",
                   text: "Welcome to HelloPhoenix!"
      end
end