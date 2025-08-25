defmodule SavvyFlags.Features.FormatValidatorTest do
  use SavvyFlags.DataCase, async: true
  alias SavvyFlags.Features.FormatValidator

  test "validates format of feature flag key" do
    format = "<app>:<feature>-YYYY-MM-DD"

    assert {:ok,
            %{
              "app" => "myapp",
              "feature" => "new-feature",
              "year" => "2023",
              "month" => "10",
              "day" => "05"
            }} =
             FormatValidator.validate("myapp:new-feature-2023-10-05", format)

    assert {:error, :no_match} = FormatValidator.validate("myapp_new-feature_2023-10-05", format)

    format = "feature-<env>-YYYYMMDD"

    assert {:ok,
            %{
              "env" => "prod",
              "year" => "2023",
              "month" => "10",
              "day" => "05"
            }} =
             FormatValidator.validate("feature-prod-20231005", format)

    assert {:error, :no_match} = FormatValidator.validate("feature-prod-2023-10-05", format)
  end
end
