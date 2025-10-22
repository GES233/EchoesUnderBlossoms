defmodule HanaShirabeWeb.MemberLive.Registration do
  use HanaShirabeWeb, :live_view

  alias HanaShirabe.Accounts
  alias HanaShirabe.Accounts.Member

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header>
            Register for an account
            <:subtitle>
              Already registered?
              <.link navigate={~p"/members/log-in"} class="font-semibold text-brand hover:underline">
                Log in
              </.link>
              to your account now.
            </:subtitle>
          </.header>
        </div>

        <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
            phx-mounted={JS.focus()}
          />

          <.button phx-disable-with="Creating account..." class="btn btn-primary w-full">
            Create an account
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{member: member}}} = socket)
      when not is_nil(member) do
    {:ok, redirect(socket, to: HanaShirabeWeb.MemberAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_member_email(%Member{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"member" => member_params}, socket) do
    case Accounts.register_member(member_params) do
      {:ok, member} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            member,
            &url(~p"/members/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{member.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/members/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"member" => member_params}, socket) do
    changeset = Accounts.change_member_email(%Member{}, member_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "member")
    assign(socket, form: form)
  end
end
