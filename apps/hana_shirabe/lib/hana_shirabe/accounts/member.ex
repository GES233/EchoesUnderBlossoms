defmodule HanaShirabe.Accounts.Member do
  use Ecto.Schema
  import Ecto.Changeset

  # 因为这里的信息可能会传导到网页（通过 Phoenix Conreoller 或 LiveView）
  # 所以也一并翻译上吧。
  use Gettext, backend: HanaShirabe.Gettext

  schema "members" do
    # 来自 mix phx.gen.auth
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :naive_datetime
    field :authenticated_at, :naive_datetime, virtual: true
    # 其他信息
    field :nickname, :string
    # def validate_nickname/2
    field :status, Ecto.Enum, values: [:normal, :frozen, :blocked, :deleted], default: :normal
    # defp status_changeset/2
    # implement namy_status_transform_function
    field :prefer_locale, :string, default: Gettext.get_locale()
    field :avatar, :string, default: ""
    field :intro, :string

    timestamps()
  end

  @doc """
  注册变更集，主要负责处理用户在注册时提交的信息。

  # TODO 后续增加对昵称的约束
  """
  def registration_changeset(member, attrs, opts \\ []) do
    member
    |> cast(attrs, [:nickname, :email])
    |> validate_nickname(opts)
    |> validate_email(opts)
  end

  @doc """
  和邮件有关的变更集，主要用于注册以及更改邮件。

  其需要邮件发生变化，否则会添加错误。

  ## Options

    * `:validate_unique` - 如果你不想要确保邮件唯一性，可以设置为 false ，这在显示实时验证时很有用。
      默认是 `true` 。
  """
  def email_changeset(member, attrs, opts \\ []) do
    member
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: dgettext("account", "must have the @ sign and no spaces")
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, HanaShirabe.Repo)
      |> unique_constraint(:email)
      |> validate_email_changed()
    else
      # coveralls-ignore-next-line
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, dgettext("account", "did not change"))
    else
      changeset
    end
  end

  @doc """
  更新用户信息时的变更表，主要用于更新成员的【非敏感】信息的情况。
  """
  def update_settings_changeset(member, attrs, opts \\ []) do
    member
    |> cast(attrs, [:nickname, :prefer_locale, :intro])
    |> validate_nickname(opts)
    |> validate_prefer_locale()
  end

  defp validate_prefer_locale(changeset) do
    changeset
    |> validate_required(:prefer_locale)
    |> validate_inclusion(
      :prefer_locale,
      Gettext.known_locales(HanaShirabeWeb.Gettext),
      message: dgettext("account", "Unknown locale")
    )
  end

  @doc """
  用于更换成员密码的更换集。

  这一点很重要，因为某些算法对长密码的哈希计算可能会非常耗费资源。

  ## Options

    * `:hash_password` - 将密码进行哈希处理，以便可以安全地存储在数据库中，
      并确保密码字段被清除以防止日志泄漏。如果不需要密码哈希处理，
      并且不希望清除密码字段（例如在 LiveView 表单上使用此更改集进行验证时），
      则可以将此选项设置为 `false` 。默认值为 `true` 。
  """
  def password_changeset(member, attrs, opts \\ []) do
    member
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: dgettext("account", "does not match password"))
    |> validate_password(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    # TODO: 将错误提醒的字符串显式的通过 :message 参数表明以便实现翻译
    # 需要再看一下代码
    |> validate_length(:password, min: 12, max: 72)
    # 其他可以使用的：
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # 散列计算可以使用 `Ecto.Changeset.prepare_changes/2` 来完成，
      # 但那样会使数据库事务保持打开状态更长时间，从而影响性能。
      |> put_change(:hashed_password, Pbkdf2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp validate_nickname(changeset, _opts) do
    changeset
    |> validate_required([:nickname])
  end

  @doc """
  通过设置 `confirmed_at` 来确认账户。
  """
  def confirm_changeset(member) do
    # TODO: 一旦实现了成员状态，这里需要将 :status 改为 :normal 或什么的
    now = NaiveDateTime.utc_now(:second)
    change(member, confirmed_at: now)
  end

  @doc """
  验证密码。

  如果这里没有成员或者成员没有密码，我们调用 `Pbkdf2.no_user_verify/0` 来避免时间攻击。
  """
  def valid_password?(%HanaShirabe.Accounts.Member{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Pbkdf2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Pbkdf2.no_user_verify()
    false
  end
end
