defmodule HanaShirabe.Accounts.MemberNotifier do
  import Swoosh.Email

  alias HanaShirabe.Mailer
  alias HanaShirabe.Accounts.Member

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"HanaShirabe", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to update a member email.
  """
  def deliver_update_email_instructions(member, url) do
    deliver(member.email, "Update email instructions", """

    ==============================

    Hi #{member.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(member, url) do
    case member do
      %Member{confirmed_at: nil} -> deliver_confirmation_instructions(member, url)
      _ -> deliver_magic_link_instructions(member, url)
    end
  end

  defp deliver_magic_link_instructions(member, url) do
    deliver(member.email, "Log in instructions", """

    ==============================

    Hi #{member.email},

    You can log into your account by visiting the URL below:

    #{url}

    If you didn't request this email, please ignore this.

    ==============================
    """)
  end

  defp deliver_confirmation_instructions(member, url) do
    deliver(member.email, "Confirmation instructions", """

    ==============================

    Hi #{member.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end
end
