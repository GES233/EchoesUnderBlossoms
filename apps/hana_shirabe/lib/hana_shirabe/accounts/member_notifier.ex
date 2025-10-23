defmodule HanaShirabe.Accounts.MemberNotifier do
  @moduledoc """
  这里应该把这个 Notifier 的概念讲清楚。

  这本质上就是通过非网站应用的层面通知用户的东西，所以不一定非得通过
  Email ，通过短信、手机设备甚至是人肉通知也可以。
  """

  import Swoosh.Email

  use Gettext, backend: HanaShirabe.Gettext

  alias HanaShirabe.Mailer
  alias HanaShirabe.Accounts.Member

  # 通过应用的邮箱发送邮件。
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
  使成员更新邮件的指示。
  """
  def deliver_update_email_instructions(member, url) do
    deliver(
      member.email,
      "Update email instructions",
      dgettext(
        "deliver",
        """

        ==============================

        Hi %{member_email},

        You can change your email by visiting the URL below:

        %{url}

        If you didn't request this change, please ignore this.

        ==============================
        """,
        member_email: member.email,
        url: url
      )
    )
  end

  @doc """
  通过链接登录的指示。
  """
  def deliver_login_instructions(member, url) do
    case member do
      %Member{confirmed_at: nil} -> deliver_confirmation_instructions(member, url)
      _ -> deliver_magic_link_instructions(member, url)
    end
  end

  defp deliver_magic_link_instructions(member, url) do
    deliver(
      member.email,
      "Log in instructions",
      dgettext(
        "deliver",
        """

        ==============================

        Hi %{member_email},

        You can log into your account by visiting the URL below:

        %{url}

        If you didn't request this email, please ignore this.

        ==============================
        """,
        member_email: member.email,
        url: url
      )
    )
  end

  defp deliver_confirmation_instructions(member, url) do
    deliver(
      member.email,
      "Confirmation instructions",
      dgettext(
        "deliver",
        """

        ==============================

        Hi %{member_email},

        You can confirm your account by visiting the URL below:

        %{url}

        If you didn't create an account with us, please ignore this.

        ==============================
        """,
        member_email: member.email,
        url: url
      )
    )
  end
end
