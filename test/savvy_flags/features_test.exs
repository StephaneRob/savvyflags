defmodule SavvyFlags.FeaturesTest do
  use SavvyFlags.DataCase, async: true

  alias SavvyFlags.Projects
  alias SavvyFlags.Attributes
  alias SavvyFlags.Environments
  alias SavvyFlags.Features

  setup do
    user = SavvyFlags.AccountsFixtures.user_fixture()
    SavvyFlags.AttributesFixtures.attribute_fixture()
    SavvyFlags.EnvironmentsFixtures.environment_fixture()
    SavvyFlags.ProjectsFixtures.project_fixture()

    environments = Environments.list_environments()
    projects = Projects.list_projects()
    attributes = Attributes.list_attributes()
    %{environments: environments, user: user, projects: projects, attributes: attributes}
  end

  describe "create_feature/1" do
    test "must create feature with valid attributes", %{projects: [project]} do
      attrs = %{
        key: "test",
        default_value: %{
          value: "false",
          type: :boolean
        },
        project_id: project.id
      }

      assert {:ok, feature} = SavvyFlags.Features.create_feature(attrs)
      assert feature.key == "test"
      assert feature.project_id == project.id
    end

    test "must return error when creating feature with invalid attributes" do
      attrs = %{}
      assert {:error, changeset} = SavvyFlags.Features.create_feature(attrs)

      assert changeset.errors == [
               {:key, {"can't be blank", [validation: :required]}},
               {:project_id, {"can't be blank", [validation: :required]}}
             ]
    end

    @tag configuration: %{feature_key_format: "<app>:<feature>"}
    test "w/ custom format must create feature with valid attributes and format", %{
      projects: [project]
    } do
      attrs = %{
        key: "myapp:navbar",
        project_id: project.id
      }

      assert {:ok, feature} = SavvyFlags.Features.create_feature(attrs)
      assert feature.key == "myapp:navbar"
      assert feature.project_id == project.id
    end

    @tag configuration: %{feature_key_format: "<app>:<feature>"}
    test "w/ custom format must return error when creating feature with invalid key format", %{
      projects: [project]
    } do
      attrs = %{
        key: "invalid_format",
        project_id: project.id
      }

      assert {:error, changeset} = SavvyFlags.Features.create_feature(attrs)

      assert changeset.errors == [
               {:key, {"Key must match the format: <app>:<feature>", []}}
             ]
    end
  end

  describe "update_feature/1" do
    setup %{projects: projects} do
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

      %{feature: feature}
    end

    test "must update feature with valid attributes", %{feature: feature} do
      assert feature.default_value.type == :boolean

      attrs = %{
        default_value: %{
          value: "{\"john\": \"doo\"}",
          type: :json
        }
      }

      assert {:ok, feature} = SavvyFlags.Features.update_feature(feature, attrs)
      assert feature.default_value.type == :json
      assert feature.default_value.value == "{\"john\": \"doo\"}"
    end

    test "must return error when creating feature with invalid attributes", %{
      feature: feature
    } do
      attrs = %{key: nil}
      assert {:error, changeset} = SavvyFlags.Features.update_feature(feature, attrs)

      assert changeset.errors == [
               {:key, {"can't be blank", [validation: :required]}}
             ]
    end
  end

  describe "create_feature_rule/1" do
    setup %{projects: projects} do
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

      %{feature: feature}
    end

    test "must create feature rule and feature rule condition with valid attrs", %{
      feature: feature,
      environments: environments,
      attributes: attributes
    } do
      [environment] = environments
      [attribute] = attributes

      attrs = %{
        description: "test feature rule",
        feature_id: feature.id,
        environment_id: environment.id,
        value: %{
          value: "true",
          type: feature.default_value.type
        },
        feature_rule_conditions: [
          %{position: 1, attribute_id: attribute.id, type: :equal, value: "10"}
        ]
      }

      assert {:ok, feature_rule} = SavvyFlags.Features.create_feature_rule(attrs)
      assert feature_rule.feature_id == feature.id
      assert feature_rule.description == "test feature rule"
      assert feature_rule.environment_id == environment.id
      assert feature_rule.value.value == "true"
      assert feature_rule.value.type == :boolean
      assert [frc] = feature_rule.feature_rule_conditions
      assert frc.feature_rule_id == feature_rule.id
      assert frc.position == 1
      assert frc.type == :equal
      assert frc.value == "10"
      assert frc.attribute_id == attribute.id
    end
  end

  describe "update_feature_rule/1" do
    setup %{projects: projects, attributes: [attribute]} do
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

      feature_rule =
        SavvyFlags.FeaturesFixtures.feature_rule_fixture(%{
          description: "test feature rule",
          feature_id: feature.id,
          environment_id: hd(Environments.list_environments()).id,
          value: %{
            value: "true",
            type: feature.default_value.type
          },
          feature_rule_conditions: [
            %{position: 1, attribute_id: attribute.id, type: :equal, value: "10"}
          ]
        })

      %{feature: feature, feature_rule: feature_rule}
    end

    test "must update feature rule and feature rule condition with valid attrs", %{
      feature: feature,
      feature_rule: feature_rule,
      environments: [environment]
    } do
      attrs = %{
        description: "test feature rule update",
        feature_rule_conditions: []
      }

      assert {:ok, feature_rule} = SavvyFlags.Features.update_feature_rule(feature_rule, attrs)
      assert feature_rule.feature_id == feature.id
      assert feature_rule.description == "test feature rule update"
      assert feature_rule.environment_id == environment.id
      assert feature_rule.value.value == "true"
      assert feature_rule.value.type == :boolean
      assert [] = feature_rule.feature_rule_conditions
    end
  end

  describe "list_features/1" do
    setup %{projects: projects} do
      [project] = projects

      feature1 =
        SavvyFlags.FeaturesFixtures.feature_fixture(%{
          key: "test",
          project_id: project.id,
          default_value: %{
            value: "false",
            type: :boolean
          }
        })

      feature2 =
        SavvyFlags.FeaturesFixtures.feature_fixture(%{
          key: "test2",
          project_id: project.id,
          default_value: %{
            value: "red",
            type: :string
          }
        })

      feature3 =
        SavvyFlags.FeaturesFixtures.feature_fixture(%{
          key: "test3",
          project_id: project.id,
          archived_at: DateTime.utc_now(),
          default_value: %{
            value: "false",
            type: :boolean
          }
        })

      %{feature1: feature1, feature2: feature2, feature3: feature3, project: project}
    end

    test " must filter features", %{
      feature1: feature1,
      feature2: feature2,
      feature3: feature3,
      project: project
    } do
      features = Features.list_features(%{"archived" => "off"})
      assert length(features) == 2
      assert Enum.all?(features, &(&1.key in [feature1.key, feature2.key]))
      features = Features.list_features(%{"project_id" => project.id})
      assert length(features) == 2
      assert Enum.all?(features, &(&1.key in [feature1.key, feature2.key]))

      features = Features.list_features(%{"archived" => "on"})
      assert length(features) == 1
      assert Enum.all?(features, &(&1.key in [feature3.key]))

      features = Features.list_features(%{"value_type" => "string"})
      assert length(features) == 1
      assert Enum.all?(features, &(&1.key in [feature2.key]))
    end
  end

  describe "stale?" do
    @tag :skip
    test "returns true if feature is stale", %{projects: [project]} do
      feature =
        SavvyFlags.FeaturesFixtures.feature_fixture(%{
          key: "test",
          project_id: project.id,
          default_value: %{
            value: "false",
            type: :boolean
          }
        })

      feature = %{feature | last_used_at: DateTime.utc_now() |> DateTime.add(-60 * 26, :hour)}
      assert Features.stale?(feature)
    end

    @tag :skip
    test "returns false if feature is not stale", %{projects: [project]} do
      feature =
        SavvyFlags.FeaturesFixtures.feature_fixture(%{
          key: "test",
          project_id: project.id,
          default_value: %{
            value: "false",
            type: :boolean
          }
        })

      feature = %{feature | last_used_at: DateTime.utc_now() |> DateTime.add(-3, :hour)}
      refute Features.stale?(feature)
    end
  end
end
