defmodule HanaShirabe.EctoIP do
  @moduledoc """
  实现 SQLite 的 inet 类型。
  """

  use Ecto.Type

  def type, do: :string

  def cast(value) when is_binary(value) do
    case :inet.parse_address(to_charlist(value)) do
      {:ok, _} -> {:ok, value}
      {:error, _} -> :error
    end
  end

  def cast(value) when is_tuple(value) do
    case :inet.ntoa(value) do
      ip when is_list(ip) -> {:ok, to_string(ip)}
      _ -> :error
    end
  end

  def cast(_), do: :error

  def load(value) when is_binary(value) do
    case :inet.parse_address(to_charlist(value)) do
      {:ok, ip} -> {:ok, ip}
      _ -> :error
    end
  end

  def dump(value) when is_tuple(value) do
    case :inet.ntoa(value) do
      {:error, _} -> :error
      res -> {:ok, to_string(res)}
    end
  end

  def dump(value) when is_binary(value) do
    {:ok, value}
  end

  def dump(_), do: :error
end
