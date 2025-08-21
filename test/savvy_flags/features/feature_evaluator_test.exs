defmodule SavvyFlags.Features.FeatureEvaluatorTest do
  alias SavvyFlags.Projects
  alias SavvyFlags.Attributes
  alias SavvyFlags.Features
  alias SavvyFlags.Features.FeatureEvaluator
  use SavvyFlags.DataCase, async: true
  alias SavvyFlags.Environments

  setup do
    user = SavvyFlags.AccountsFixtures.user_fixture()
    SavvyFlags.AttributesFixtures.attribute_fixture(%{name: "email"})
    SavvyFlags.EnvironmentsFixtures.environment_fixture()
    SavvyFlags.ProjectsFixtures.project_fixture()

    environments = Environments.list_environments()
    projects = Projects.list_projects()
    attributes = Attributes.list_attributes()

    %{environments: environments, user: user, projects: projects, attributes: attributes}
  end

  describe "eval/2" do
    setup %{projects: projects, attributes: attributes, environments: environments} do
      [project] = projects

      feature =
        SavvyFlags.FeaturesFixtures.feature_fixture(%{
          key: "test",
          project_id: project.id,
          default_value: %{
            value: "false",
            type: :boolean
          }
        })

      email_attribute = Enum.find(attributes, &(&1.name == "email"))

      Features.create_feature_rule(%{
        feature_id: feature.id,
        description: "Activate for wttj users",
        value: %{type: :boolean, value: "true"},
        environment_id: List.first(environments).id,
        feature_rule_conditions: [
          %{
            position: 1,
            attribute_id: email_attribute.id,
            type: :match_regex,
            value: ".*\.wttj.co$"
          }
        ]
      })

      feature =
        SavvyFlags.Repo.preload(feature, feature_rules: [feature_rule_conditions: :attribute])

      %{feature: feature}
    end

    test "eval feature", %{feature: feature} do
      assert result = FeatureEvaluator.eval([feature], %{})
      assert result == %{"test" => "false"}
    end
  end

  describe "compare/2" do
    test "with :match_regex" do
      assert FeatureEvaluator.compare("stephane@wttj.co", ".*wttj\.co$", :match_regex)
      refute FeatureEvaluator.compare("stephane@gmail.co", ".*wttj\.co$", :match_regex)
      assert FeatureEvaluator.compare("stephane@gmail.co", "^stephane.*", :match_regex)
      refute FeatureEvaluator.compare("robert@gmail.co", "^stephane.*", :match_regex)
    end

    test "with :not_match_regex" do
      refute FeatureEvaluator.compare("stephane@wttj.co", ".*wttj\.co$", :not_match_regex)
      assert FeatureEvaluator.compare("stephane@gmail.co", ".*wttj\.co$", :not_match_regex)
      refute FeatureEvaluator.compare("stephane@gmail.co", "^stephane.*", :not_match_regex)
      assert FeatureEvaluator.compare("robert@gmail.co", "^stephane.*", :not_match_regex)
    end

    test "with :equal" do
      assert FeatureEvaluator.compare("stephane@wttj.co", "stephane@wttj.co", :equal)
      refute FeatureEvaluator.compare("stephane@gmail.co", "whatever", :equal)
    end

    test "with :not_equal" do
      refute FeatureEvaluator.compare("stephane@wttj.co", "stephane@wttj.co", :not_equal)
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
