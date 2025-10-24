defmodule HanaShirabe.Accounts.Member do
  use Ecto.Schema
  import Ecto.Changeset

  # 因为这里的信息可能会传导到网页（通过 Phoenix Conreoller 或 LiveView）
  # 所以也一并翻译上吧。
  use Gettext, backend: HanaShirabe.Gettext

  schema "members" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :naive_datetime
    field :authenticated_at, :naive_datetime, virtual: true

    timestamps()
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
        message: dgettext("member", "must have the @ sign and no spaces")
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, HanaShirabe.Repo)
      |> unique_constraint(:email)
      |> validate_email_changed()
    else
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, dgettext("member", "did not change"))
    else
      changeset
    end
  end

  @doc """
  A member changeset for changing the password.

  It is important to validate the length of the password, as long passwords may
  be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(member, attrs, opts \\ []) do
    member
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: dgettext("member", "does not match password"))
    |> validate_password(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
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
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Argon2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(member) do
    now = NaiveDateTime.utc_now(:second)
    change(member, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no member or the member doesn't have a password, we call
  `Argon2.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%HanaShirabe.Accounts.Member{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Argon2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Argon2.no_user_verify()
    false
  end
end
