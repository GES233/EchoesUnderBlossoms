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
  def deliver_update_email_instructions(member, code, url) do
    deliver(
      member.email,
      dgettext("deliver", "Update email instructions"),
      dgettext(
        "deliver",
        """

        ==============================

        Hi %{member_email},

        Welcome to Echoes Under Blossoms.

        Please use the following code to change your email:

        %{code}

        Alternatively, you can sign in by visiting the link below:

        %{url}

        This request is valid for 15 minutes. If you did not request this, please ignore this email.
        ==============================
        """,
        member_email: member.email,
        code: code,
        url: url
      )
    )
  end

  @doc """
  通过链接登录的指示。
  """
  def deliver_login_instructions(member, code, url) do
    case member do
      %Member{confirmed_at: nil} -> deliver_confirmation_instructions(member, code, url)
      _ -> deliver_magic_link_instructions(member, code, url)
    end
  end

  defp deliver_magic_link_instructions(member, code, url) do
    deliver(
      member.email,
      dgettext("deliver", "Log in instructions"),
      dgettext(
        "deliver",
        """

        ==============================

        Hi %{member_email},

        Welcome to Echoes Under Blossoms.

        Please use the following code to complete your log in:

        %{code}

        Alternatively, you can sign in by visiting the link below:

        %{url}

        This request is valid for 15 minutes. If you did not request this, please ignore this email.

        ==============================
        """,
        member_email: member.email,
        code: code,
        url: url
      )
    )
  end

  # 注册就别用 Code 了吧。
  defp deliver_confirmation_instructions(member, _code, url) do
    deliver(
      member.email,
      dgettext("deliver", "Confirmation instructions"),
      dgettext(
        "deliver",
        """

        ==============================

        Hi %{member_email},

        Welcome to Echoes Under Blossoms.

        Please visit the link below:

        %{url}

        This request is valid for 15 minutes. If you did not request this, please ignore this email.

        ==============================
        """,
        member_email: member.email,
        url: url
      )
    )
  end
end
