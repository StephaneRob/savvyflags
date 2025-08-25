defmodule SavvyFlagsWeb.UI do
  defmacro __using__(_) do
    quote do
      import SavvyFlagsWeb.UIHelpers
      import SavvyFlagsWeb.UI.Button
      import SavvyFlagsWeb.UI.Input
      import SavvyFlagsWeb.UI.Modal
      import SavvyFlagsWeb.UI.Table
      import SavvyFlagsWeb.UI.Header
      import SavvyFlagsWeb.UI.Label
      import SavvyFlagsWeb.UI.Flash
      import SavvyFlagsWeb.UI.Back
      import SavvyFlagsWeb.UI.Icon
      import SavvyFlagsWeb.UI.List
      import SavvyFlagsWeb.UI.Error
      import SavvyFlagsWeb.UI.Form
      import SavvyFlagsWeb.UI.CopyToClipboard
      import SavvyFlagsWeb.UI.Breadcrumb
      import SavvyFlagsWeb.UI.Datetime
      import SavvyFlagsWeb.UI.Tag
      import SavvyFlagsWeb.UI.Badge
      import SavvyFlagsWeb.UI.Check
      import SavvyFlagsWeb.UI.Toggle
      import SavvyFlagsWeb.UI.NavLink
    end
  end
end
