defmodule HanaShirabe.AccountsTest do
  use HanaShirabe.DataCase

  alias HanaShirabe.Accounts

  import HanaShirabe.AccountsFixtures
  alias HanaShirabe.Accounts.{Member, MemberToken}

  describe "测试 get_member_by_email/1" do
    test "如果邮件不存在不要返回用户" do
      refute Accounts.get_member_by_email("unknown@example.com")
    end

    test "邮件存在返回用户" do
      %{id: id} = member = member_fixture()
      assert %Member{id: ^id} = Accounts.get_member_by_email(member.email)
    end
  end

  describe "测试 get_member_by_email_and_password/2" do
    test "邮件不存在不返回用户" do
      refute Accounts.get_member_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "密码不对不返回用户" do
      member = member_fixture() |> set_password()
      refute Accounts.get_member_by_email_and_password(member.email, "invalid")
    end

    test "邮件与密码都合法将返回成员" do
      %{id: id} = member = member_fixture() |> set_password()

      assert %Member{id: ^id} =
               Accounts.get_member_by_email_and_password(member.email, valid_member_password())
    end
  end

  describe "测试 get_member!/1" do
    test "一旦无成员报错" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_member!(-1)
      end
    end

    test "通过给定 id 返回成员" do
      %{id: id} = member = member_fixture()
      assert %Member{id: ^id} = Accounts.get_member!(member.id)
    end
  end

  describe "测试 register_member/2" do
    # 整段亟待重构
    # test "注册需要邮件" do
    #   {:error, changeset} = Accounts.register_member(%{})
    #   %{email: [error_msg]} = errors_on(changeset)

    #   assert error_msg == dgettext("account", "can't be blank")
    # end

    # test "validates email when given" do
    #   {:error, changeset} = Accounts.register_member(%{email: "not valid"})
    #   %{email: [error_msg]} = errors_on(changeset)

    #   assert error_msg == dgettext("account", "must have the @ sign and no spaces")
    # end

    # test "validates maximum values for email for security" do
    #   too_long = String.duplicate("db", 100)
    #   {:error, changeset} = Accounts.register_member(%{email: too_long})
    #   assert "should be at most 160 character(s)" in errors_on(changeset).email
    # end

    # test "validates email uniqueness" do
    #   %{email: email} = member_fixture()
    #   {:error, changeset} = Accounts.register_member(%{email: email})
    #   assert "has already been taken" in errors_on(changeset).email

    #   # Now try with the upper cased email too, to check that email case is ignored.
    #   {:error, changeset} = Accounts.register_member(%{email: String.upcase(email)})
    #   assert "has already been taken" in errors_on(changeset).email
    # end

    # test "registers members without password" do
    #   email = unique_member_email()
    #   {:ok, member} = Accounts.register_member(valid_member_attributes(email: email))
    #   assert member.email == email
    #   assert is_nil(member.hashed_password)
    #   assert is_nil(member.confirmed_at)
    #   assert is_nil(member.password)
    # end

    # 需要更新需要事务日志的测试用例
  end

  describe "测试 sudo_mode?/2" do
    test "检查成员的认证时间相关" do
      now = NaiveDateTime.utc_now()

      assert Accounts.sudo_mode?(%Member{authenticated_at: NaiveDateTime.utc_now()})
      assert Accounts.sudo_mode?(%Member{authenticated_at: NaiveDateTime.add(now, -19, :minute)})
      refute Accounts.sudo_mode?(%Member{authenticated_at: NaiveDateTime.add(now, -21, :minute)})

      # minute override
      # 超时了（？）
      refute Accounts.sudo_mode?(
               %Member{authenticated_at: NaiveDateTime.add(now, -11, :minute)},
               -10
             )

      # 未认证
      refute Accounts.sudo_mode?(%Member{})
    end
  end

  describe "测试 change_member_email/3" do
    test "返回成员变更集" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_member_email(%Member{})
      assert changeset.required == [:email]
    end
  end

  describe "测试 deliver_member_update_email_instructions/3" do
    setup do
      %{member: member_fixture()}
    end

    test "通过 notification 发送消息", %{member: member} do
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

  describe "测试 update_member_email/2" do
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

  describe "测试 change_member_password/3" do
    test "返回成员变更集" do
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

  describe "测试 update_member_password/2" do
    setup do
      %{member: member_fixture()}
    end

    test "检查密码", %{member: member} do
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

    test "更新密码", %{member: member} do
      {:ok, {member, expired_tokens}} =
        Accounts.update_member_password(member, %{
          password: "new valid password"
        })

      assert expired_tokens == []
      assert is_nil(member.password)
      assert Accounts.get_member_by_email_and_password(member.email, "new valid password")
    end

    test "删除给定成员的所有令牌", %{member: member} do
      _ = Accounts.generate_member_session_token(member)

      {:ok, {_, _}} =
        Accounts.update_member_password(member, %{
          password: "new valid password"
        })

      refute Repo.get_by(MemberToken, member_id: member.id)
    end
  end

  describe "测试 generate_member_session_token/1" do
    setup do
      %{member: member_fixture()}
    end

    test "生成令牌", %{member: member} do
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

  describe "测试 get_member_by_session_token/1" do
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

  describe "测试 get_member_by_magic_link_token/1" do
    setup do
      member = member_fixture()
      {encoded_token, _hashed_token} = generate_member_magic_link_token(member)
      %{member: member, token: encoded_token}
    end

    test "通过令牌返回用户", %{member: member, token: token} do
      assert session_member = Accounts.get_member_by_magic_link_token(token)
      assert session_member.id == member.id
    end

    test "令牌不合法不返回用户" do
      refute Accounts.get_member_by_magic_link_token("oops")
    end

    test "过期令牌不返回用户", %{token: token} do
      {1, nil} = Repo.update_all(MemberToken, set: [inserted_at: ~N[2000-01-01 00:00:00]])
      refute Accounts.get_member_by_magic_link_token(token)
    end
  end

  describe "测试 login_member_by_magic_link/1" do
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

  describe "测试 delete_member_session_token/1" do
    test "删除令牌" do
      member = member_fixture()
      token = Accounts.generate_member_session_token(member)
      assert Accounts.delete_member_session_token(token) == :ok
      refute Accounts.get_member_by_session_token(token)
    end
  end

  describe "测试 deliver_login_instructions/2" do
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

  describe "测试用于成员结构体的 inspect/2" do
    test "不要显示密码" do
      # 也实现不了，因为 password 是 vitual 字段
      refute inspect(%Member{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
