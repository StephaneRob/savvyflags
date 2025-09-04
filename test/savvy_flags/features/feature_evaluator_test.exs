defmodule SavvyFlags.Features.EvaluatorTest do
  use SavvyFlags.DataCase, async: true

  alias SavvyFlags.Features.Evaluator

  import SavvyFlags.ProjectsFixtures
  import SavvyFlags.AttributesFixtures
  import SavvyFlags.EnvironmentsFixtures
  import SavvyFlags.AccountsFixtures
  import SavvyFlags.FeaturesFixtures

  setup do
    user = user_fixture()
    attribute = attribute_fixture(%{name: "email"})
    environment = environment_fixture()
    project = project_fixture()

    %{environment: environment, user: user, project: project, attribute: attribute}
  end

  describe "eval/2" do
    setup %{project: project, attribute: attribute, environment: environment, user: user} do
      feature =
        feature_with_published_revision_fixture(%{
          key: "test",
          project_id: project.id,
          current_user_id: user.id
        })

      rule_fixture(%{
        revision_id: feature.last_revision.id,
        description: "Activate for example users",
        value: %{type: :boolean, value: "true"},
        environment_id: environment.id,
        conditions: [
          %{
            position: 1,
            attribute: attribute.name,
            type: :match_regex,
            value: ".*\.example.co$"
          }
        ]
      })

      feature =
        SavvyFlags.Repo.preload(feature, current_revision: :rules)

      %{feature: feature}
    end

    test "eval feature", %{feature: feature} do
      assert result = Evaluator.eval([feature], %{})
      assert result == %{"test" => "false"}
    end
  end

  describe "compare/2" do
    test "with :match_regex" do
      assert Evaluator.compare("stephane@example.co", ".*example\.co$", :match_regex)
      refute Evaluator.compare("stephane@gmail.co", ".*example\.co$", :match_regex)
      assert Evaluator.compare("stephane@gmail.co", "^stephane.*", :match_regex)
      refute Evaluator.compare("robert@gmail.co", "^stephane.*", :match_regex)
    end

    test "with :not_match_regex" do
      refute Evaluator.compare("stephane@example.co", ".*example\.co$", :not_match_regex)
      assert Evaluator.compare("stephane@gmail.co", ".*example\.co$", :not_match_regex)
      refute Evaluator.compare("stephane@gmail.co", "^stephane.*", :not_match_regex)
      assert Evaluator.compare("robert@gmail.co", "^stephane.*", :not_match_regex)
    end

    test "with :equal" do
      assert Evaluator.compare("stephane@example.co", "stephane@example.co", :equal)
      refute Evaluator.compare("stephane@gmail.co", "whatever", :equal)
    end

    test "with :not_equal" do
      refute Evaluator.compare("stephane@example.co", "stephane@example.co", :not_equal)
      assert Evaluator.compare("stephane@gmail.co", "whatever", :not_equal)
    end

    test "with :gt" do
      assert Evaluator.compare("10", "8", :gt)
      refute Evaluator.compare("10", "10", :gt)
      refute Evaluator.compare("10", "20", :gt)
      refute Evaluator.compare("", "20", :gt)
      assert Evaluator.compare(10, "8", :gt)
    end

    test "with :gt_or_equal" do
      assert Evaluator.compare("10", "8", :gt_or_equal)
      assert Evaluator.compare("10", "10", :gt_or_equal)
      refute Evaluator.compare("10", "20", :gt_or_equal)
    end

    test "with :lt" do
      refute Evaluator.compare("10", "8", :lt)
      refute Evaluator.compare("10", "10", :lt)
      assert Evaluator.compare("10", "20", :lt)
    end

    test "with :lt_or_equal" do
      refute Evaluator.compare("10", "8", :lt_or_equal)
      assert Evaluator.compare("10", "10", :lt_or_equal)
      assert Evaluator.compare("10", "20", :lt_or_equal)
    end

    test "with :sample" do
      refute Evaluator.compare("stephane", "30", :sample)
      refute Evaluator.compare(nil, "30", :sample)
      assert Evaluator.compare("Johny", "30", :sample)
    end

    test "with :in" do
      assert Evaluator.compare("stephane", "stephane, john", :in)
      refute Evaluator.compare("Johny", "stephane, john", :in)
    end

    test "with :not_in" do
      refute Evaluator.compare("stephane", "stephane, john", :not_in)
      assert Evaluator.compare("Johny", "stephane, john", :not_in)
    end
  end
end
