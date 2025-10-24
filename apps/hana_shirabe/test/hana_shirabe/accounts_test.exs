defmodule HanaShirabe.AccountsTest do
  use HanaShirabe.DataCase

  alias HanaShirabe.Accounts

  import HanaShirabe.AccountsFixtures
  alias HanaShirabe.Accounts.{Member, MemberToken}

  describe "get_member_by_email/1" do
    test "does not return the member if the email does not exist" do
      refute Accounts.get_member_by_email("unknown@example.com")
    end

    test "returns the member if the email exists" do
      %{id: id} = member = member_fixture()
      assert %Member{id: ^id} = Accounts.get_member_by_email(member.email)
    end
  end

  describe "get_member_by_email_and_password/2" do
    test "does not return the member if the email does not exist" do
      refute Accounts.get_member_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the member if the password is not valid" do
      member = member_fixture() |> set_password()
      refute Accounts.get_member_by_email_and_password(member.email, "invalid")
    end

    test "returns the member if the email and password are valid" do
      %{id: id} = member = member_fixture() |> set_password()

      assert %Member{id: ^id} =
               Accounts.get_member_by_email_and_password(member.email, valid_member_password())
    end
  end

  describe "get_member!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_member!(-1)
      end
    end

    test "returns the member with the given id" do
      %{id: id} = member = member_fixture()
      assert %Member{id: ^id} = Accounts.get_member!(member.id)
    end
  end

  describe "register_member/1" do
    test "requires email to be set" do
      {:error, changeset} = Accounts.register_member(%{})

      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates email when given" do
      {:error, changeset} = Accounts.register_member(%{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum values for email for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_member(%{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness" do
      %{email: email} = member_fixture()
      {:error, changeset} = Accounts.register_member(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_member(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers members without password" do
      email = unique_member_email()
      {:ok, member} = Accounts.register_member(valid_member_attributes(email: email))
      assert member.email == email
      assert is_nil(member.hashed_password)
      assert is_nil(member.confirmed_at)
      assert is_nil(member.password)
    end
  end

  describe "sudo_mode?/2" do
    test "validates the authenticated_at time" do
      now = NaiveDateTime.utc_now()

      assert Accounts.sudo_mode?(%Member{authenticated_at: NaiveDateTime.utc_now()})
      assert Accounts.sudo_mode?(%Member{authenticated_at: NaiveDateTime.add(now, -19, :minute)})
      refute Accounts.sudo_mode?(%Member{authenticated_at: NaiveDateTime.add(now, -21, :minute)})

      # minute override
      refute Accounts.sudo_mode?(
               %Member{authenticated_at: NaiveDateTime.add(now, -11, :minute)},
               -10
             )

      # not authenticated
      refute Accounts.sudo_mode?(%Member{})
    end
  end

  describe "change_member_email/3" do
    test "returns a member changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_member_email(%Member{})
      assert changeset.required == [:email]
    end
  end

  describe "deliver_member_update_email_instructions/3" do
    setup do
      %{member: member_fixture()}
    end

    test "sends token through notification", %{member: member} do
      token =
        extract_member_token(fn url ->
          Accounts.deliver_member_update_email_instructions(member, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert member_token = Repo.get_by(MemberToken, token: :crypto.hash(:sha256, token))
      assert member_token.member_id == member.id
      assert member_token.sent_to == member.email
      assert member_token.context == "change:current@example.com"
    end
  end

  describe "update_member_email/2" do
    setup do
      member = unconfirmed_member_fixture()
      email = unique_member_email()

      token =
        extract_member_token(fn url ->
          Accounts.deliver_member_update_email_instructions(%{member | email: email}, member.email, url)
        end)

      %{member: member, token: token, email: email}
    end

    test "updates the email with a valid token", %{member: member, token: token, email: email} do
      assert {:ok, %{email: ^email}} = Accounts.update_member_email(member, token)
      changed_member = Repo.get!(Member, member.id)
      assert changed_member.email != member.email
      assert changed_member.email == email
      refute Repo.get_by(MemberToken, member_id: member.id)
    end

    test "does not update email with invalid token", %{member: member} do
      assert Accounts.update_member_email(member, "oops") ==
               {:error, :transaction_aborted}

      assert Repo.get!(Member, member.id).email == member.email
      assert Repo.get_by(MemberToken, member_id: member.id)
    end

    test "does not update email if member email changed", %{member: member, token: token} do
      assert Accounts.update_member_email(%{member | email: "current@example.com"}, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(Member, member.id).email == member.email
      assert Repo.get_by(MemberToken, member_id: member.id)
    end

    test "does not update email if token expired", %{member: member, token: token} do
      {1, nil} = Repo.update_all(MemberToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      assert Accounts.update_member_email(member, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(Member, member.id).email == member.email
      assert Repo.get_by(MemberToken, member_id: member.id)
    end
  end

  describe "change_member_password/3" do
    test "returns a member changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_member_password(%Member{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_member_password(
          %Member{},
          %{
            "password" => "new valid password"
          },
          hash_password: false
        )

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_member_password/2" do
    setup do
      %{member: member_fixture()}
    end

    test "validates password", %{member: member} do
      {:error, changeset} =
        Accounts.update_member_password(member, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{member: member} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_member_password(member, %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{member: member} do
      {:ok, {member, expired_tokens}} =
        Accounts.update_member_password(member, %{
          password: "new valid password"
        })

      assert expired_tokens == []
      assert is_nil(member.password)
      assert Accounts.get_member_by_email_and_password(member.email, "new valid password")
    end

    test "deletes all tokens for the given member", %{member: member} do
      _ = Accounts.generate_member_session_token(member)

      {:ok, {_, _}} =
        Accounts.update_member_password(member, %{
          password: "new valid password"
        })

      refute Repo.get_by(MemberToken, member_id: member.id)
    end
  end

  describe "generate_member_session_token/1" do
    setup do
      %{member: member_fixture()}
    end

    test "generates a token", %{member: member} do
      token = Accounts.generate_member_session_token(member)
      assert member_token = Repo.get_by(MemberToken, token: token)
      assert member_token.context == "session"
      assert member_token.authenticated_at != nil

      # Creating the same token for another member should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%MemberToken{
          token: member_token.token,
          member_id: member_fixture().id,
          context: "session"
        })
      end
    end

    test "duplicates the authenticated_at of given member in new token", %{member: member} do
      member = %{member | authenticated_at: NaiveDateTime.add(NaiveDateTime.utc_now(:second), -3600)}
      token = Accounts.generate_member_session_token(member)
      assert member_token = Repo.get_by(MemberToken, token: token)
      assert member_token.authenticated_at == member.authenticated_at
      assert NaiveDateTime.compare(member_token.inserted_at, member.authenticated_at) == :gt
    end
  end

  describe "get_member_by_session_token/1" do
    setup do
      member = member_fixture()
      token = Accounts.generate_member_session_token(member)
      %{member: member, token: token}
    end

    test "returns member by token", %{member: member, token: token} do
      assert {session_member, token_inserted_at} = Accounts.get_member_by_session_token(token)
      assert session_member.id == member.id
      assert session_member.authenticated_at != nil
      assert token_inserted_at != nil
    end

    test "does not return member for invalid token" do
      refute Accounts.get_member_by_session_token("oops")
    end

    test "does not return member for expired token", %{token: token} do
      dt = ~N[2020-01-01 00:00:00]
      {1, nil} = Repo.update_all(MemberToken, set: [inserted_at: dt, authenticated_at: dt])
      refute Accounts.get_member_by_session_token(token)
    end
  end

  describe "get_member_by_magic_link_token/1" do
    setup do
      member = member_fixture()
      {encoded_token, _hashed_token} = generate_member_magic_link_token(member)
      %{member: member, token: encoded_token}
    end

    test "returns member by token", %{member: member, token: token} do
      assert session_member = Accounts.get_member_by_magic_link_token(token)
      assert session_member.id == member.id
    end

    test "does not return member for invalid token" do
      refute Accounts.get_member_by_magic_link_token("oops")
    end

    test "does not return member for expired token", %{token: token} do
      {1, nil} = Repo.update_all(MemberToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_member_by_magic_link_token(token)
    end
  end

  describe "login_member_by_magic_link/1" do
    test "confirms member and expires tokens" do
      member = unconfirmed_member_fixture()
      refute member.confirmed_at
      {encoded_token, hashed_token} = generate_member_magic_link_token(member)

      assert {:ok, {member, [%{token: ^hashed_token}]}} =
               Accounts.login_member_by_magic_link(encoded_token)

      assert member.confirmed_at
    end

    test "returns member and (deleted) token for confirmed member" do
      member = member_fixture()
      assert member.confirmed_at
      {encoded_token, _hashed_token} = generate_member_magic_link_token(member)
      assert {:ok, {^member, []}} = Accounts.login_member_by_magic_link(encoded_token)
      # one time use only
      assert {:error, :not_found} = Accounts.login_member_by_magic_link(encoded_token)
    end

    test "raises when unconfirmed member has password set" do
      member = unconfirmed_member_fixture()
      {1, nil} = Repo.update_all(Member, set: [hashed_password: "hashed"])
      {encoded_token, _hashed_token} = generate_member_magic_link_token(member)

      assert_raise RuntimeError, ~r/magic link log in is not allowed/, fn ->
        Accounts.login_member_by_magic_link(encoded_token)
      end
    end
  end

  describe "delete_member_session_token/1" do
    test "deletes the token" do
      member = member_fixture()
      token = Accounts.generate_member_session_token(member)
      assert Accounts.delete_member_session_token(token) == :ok
      refute Accounts.get_member_by_session_token(token)
    end
  end

  describe "deliver_login_instructions/2" do
    setup do
      %{member: unconfirmed_member_fixture()}
    end

    test "sends token through notification", %{member: member} do
      token =
        extract_member_token(fn url ->
          Accounts.deliver_login_instructions(member, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert member_token = Repo.get_by(MemberToken, token: :crypto.hash(:sha256, token))
      assert member_token.member_id == member.id
      assert member_token.sent_to == member.email
      assert member_token.context == "login"
    end
  end

  describe "inspect/2 for the Member module" do
    test "does not include password" do
      refute inspect(%Member{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
