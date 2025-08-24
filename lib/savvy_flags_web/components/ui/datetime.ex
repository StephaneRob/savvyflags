defmodule SavvyFlagsWeb.UI.Datetime do
  use Phoenix.Component

  attr :value, :string, required: true
  attr :format, :string, default: "%Y-%m-%d"

  def datetime(assigns) do
    ~H"""
    {Timex.format!(@value, @format, :strftime)}
    """
  end
end
