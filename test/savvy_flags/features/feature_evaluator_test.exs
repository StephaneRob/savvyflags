defmodule SavvyFlags.Features.FeatureEvaluatorTest do
  use SavvyFlags.DataCase, async: true

  alias SavvyFlags.Features.FeatureEvaluator

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

      feature_rule_fixture(%{
        feature_revision_id: feature.last_feature_revision.id,
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
        SavvyFlags.Repo.preload(feature, current_feature_revision: :feature_rules)

      %{feature: feature}
    end

    test "eval feature", %{feature: feature} do
      assert result = FeatureEvaluator.eval([feature], %{})
      assert result == %{"test" => "false"}
    end
  end

  describe "compare/2" do
    test "with :match_regex" do
      assert FeatureEvaluator.compare("stephane@example.co", ".*example\.co$", :match_regex)
      refute FeatureEvaluator.compare("stephane@gmail.co", ".*example\.co$", :match_regex)
      assert FeatureEvaluator.compare("stephane@gmail.co", "^stephane.*", :match_regex)
      refute FeatureEvaluator.compare("robert@gmail.co", "^stephane.*", :match_regex)
    end

    test "with :not_match_regex" do
      refute FeatureEvaluator.compare("stephane@example.co", ".*example\.co$", :not_match_regex)
      assert FeatureEvaluator.compare("stephane@gmail.co", ".*example\.co$", :not_match_regex)
      refute FeatureEvaluator.compare("stephane@gmail.co", "^stephane.*", :not_match_regex)
      assert FeatureEvaluator.compare("robert@gmail.co", "^stephane.*", :not_match_regex)
    end

    test "with :equal" do
      assert FeatureEvaluator.compare("stephane@example.co", "stephane@example.co", :equal)
      refute FeatureEvaluator.compare("stephane@gmail.co", "whatever", :equal)
    end

    test "with :not_equal" do
      refute FeatureEvaluator.compare("stephane@example.co", "stephane@example.co", :not_equal)
      assert FeatureEvaluator.compare("stephane@gmail.co", "whatever", :not_equal)
    end

    test "with :gt" do
      assert FeatureEvaluator.compare("10", "8", :gt)
      refute FeatureEvaluator.compare("10", "10", :gt)
      refute FeatureEvaluator.compare("10", "20", :gt)
      refute FeatureEvaluator.compare("", "20", :gt)
      assert FeatureEvaluator.compare(10, "8", :gt)
    end

    test "with :gt_or_equal" do
      assert FeatureEvaluator.compare("10", "8", :gt_or_equal)
      assert FeatureEvaluator.compare("10", "10", :gt_or_equal)
      refute FeatureEvaluator.compare("10", "20", :gt_or_equal)
    end

    test "with :lt" do
      refute FeatureEvaluator.compare("10", "8", :lt)
      refute FeatureEvaluator.compare("10", "10", :lt)
      assert FeatureEvaluator.compare("10", "20", :lt)
    end

    test "with :lt_or_equal" do
      refute FeatureEvaluator.compare("10", "8", :lt_or_equal)
      assert FeatureEvaluator.compare("10", "10", :lt_or_equal)
      assert FeatureEvaluator.compare("10", "20", :lt_or_equal)
    end

    test "with :sample" do
      refute FeatureEvaluator.compare("stephane", "30", :sample)
      refute FeatureEvaluator.compare(nil, "30", :sample)
      assert FeatureEvaluator.compare("Johny", "30", :sample)
    end

    test "with :in" do
      assert FeatureEvaluator.compare("stephane", "stephane, john", :in)
      refute FeatureEvaluator.compare("Johny", "stephane, john", :in)
    end

    test "with :not_in" do
      refute FeatureEvaluator.compare("stephane", "stephane, john", :not_in)
      assert FeatureEvaluator.compare("Johny", "stephane, john", :not_in)
    end
  end
end
