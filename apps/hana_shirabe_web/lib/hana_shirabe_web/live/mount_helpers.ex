defmodule HanaShirabeWeb.MountHelpers do
  import Phoenix.Component

  alias HanaShirabeWeb.RequestContext

  def assign_default(socket, session) do
    socket
    |> assign_current_user(session)
    |> RequestContext.put_audit_context()
  end

  defp assign_current_user(socket, _session) do
    assign_new(socket, :current_user, fn ->
      nil
    end)
  end
end
