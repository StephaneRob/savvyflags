defmodule SavvyFlags.FeaturesTest do
  use SavvyFlags.DataCase, async: true

  alias SavvyFlags.Features

  import SavvyFlags.FeaturesFixtures
  import SavvyFlags.AccountsFixtures
  import SavvyFlags.AttributesFixtures
  import SavvyFlags.EnvironmentsFixtures
  import SavvyFlags.ProjectsFixtures

  setup do
    user = user_fixture()
    attribute = attribute_fixture()
    environment = environment_fixture()
    project = project_fixture()

    %{environment: environment, user: user, project: project, attribute: attribute}
  end

  describe "create_feature/1" do
    test "must create feature with valid attributes", %{project: project, user: user} do
      attrs = %{
        key: "test",
        feature_revisions: [
          %{
            value: %{
              value: "false",
              type: :boolean
            },
            created_by_id: user.id,
            updated_by_id: user.id
          }
        ],
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
      project: project
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
      project: project
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

  # describe "update_feature/1" do
  #   setup %{project: project, user: user} do
  #     feature =
  #       feature_fixture(%{
  #         current_user_id: user.id,
  #         key: "test",
  #         project_id: project.id
  #       })

  #     %{feature: feature}
  #   end

  #   test "must update feature with valid attributes", %{feature: feature} do
  #     [feature_revision] = feature.feature_revisions
  #     assert feature_revision.value.type == :boolean

  #     attrs = %{
  #       value: %{
  #         value: "{\"john\": \"doo\"}",
  #         type: :json
  #       }
  #     }

  #     assert {:ok, feature} = SavvyFlags.Features.update_feature(feature, attrs)
  #     assert feature.default_value.type == :json
  #     assert feature.default_value.value == "{\"john\": \"doo\"}"
  #   end

  #   test "must return error when creating feature with invalid attributes", %{
  #     feature: feature
  #   } do
  #     attrs = %{key: nil}
  #     assert {:error, changeset} = SavvyFlags.Features.update_feature(feature, attrs)

  #     assert changeset.errors == [
  #              {:key, {"can't be blank", [validation: :required]}}
  #            ]
  #   end
  # end

  describe "create_feature_rule/1" do
    setup %{project: project, user: user} do
      feature =
        feature_fixture(%{
          current_user_id: user.id,
          key: "test",
          project_id: project.id
        })

      %{feature: feature}
    end

    test "must create feature rule and feature rule condition with valid attrs", %{
      feature: feature,
      environment: environment
    } do
      attrs = %{
        description: "test feature rule",
        environment_id: environment.id,
        feature_revision_id: feature.last_feature_revision.id,
        value: %{
          value: "true",
          type: feature.last_feature_revision.value.type
        },
        conditions: [
          %{position: 1, attribute: "id", type: :equal, value: "10"}
        ]
      }

      assert {:ok, feature_rule} = SavvyFlags.Features.create_feature_rule(attrs)
      assert feature_rule.feature_revision_id == feature.last_feature_revision.id
      assert feature_rule.description == "test feature rule"
      assert feature_rule.environment_id == environment.id
      assert feature_rule.value.value == "true"
      assert feature_rule.value.type == :boolean
      assert [frc] = feature_rule.conditions
      assert frc.type == :equal
      assert frc.value == "10"
      assert frc.attribute == "id"
    end
  end

  describe "update_feature_rule/1" do
    setup %{project: project, user: user, environment: environment} do
      feature =
        feature_fixture(%{
          current_user_id: user.id,
          key: "test",
          project_id: project.id
        })

      feature_rule =
        feature_rule_fixture(%{
          description: "test feature rule",
          feature_revision_id: feature.last_feature_revision.id,
          environment_id: environment.id,
          value: %{
            value: "true",
            type: feature.last_feature_revision.value.type
          },
          conditions: [
            %{position: 1, attribute: "id", type: :equal, value: "10"}
          ]
        })

      %{feature: feature, feature_rule: feature_rule}
    end

    test "must update feature rule and feature rule condition with valid attrs", %{
      feature_rule: feature_rule,
      environment: environment
    } do
      attrs = %{
        description: "test feature rule update",
        conditions: []
      }

      assert {:ok, feature_rule} = SavvyFlags.Features.update_feature_rule(feature_rule, attrs)
      assert feature_rule.description == "test feature rule update"
      assert feature_rule.environment_id == environment.id
      assert feature_rule.value.value == "true"
      assert feature_rule.value.type == :boolean
      assert [] = feature_rule.conditions
    end
  end

  describe "list_features/1" do
    setup %{project: project, user: user} do
      feature1 =
        feature_fixture(%{
          current_user_id: user.id,
          key: "test",
          project_id: project.id,
          feature_revisions: [
            %{
              value: %{
                value: "false",
                type: :boolean
              },
              created_by_id: user.id,
              updated_by_id: user.id
            }
          ]
        })

      feature2 =
        feature_fixture(%{
          key: "test2",
          project_id: project.id,
          feature_revisions: [
            %{
              value: %{
                value: "red",
                type: :string
              },
              created_by_id: user.id,
              updated_by_id: user.id
            }
          ]
        })

      feature3 =
        feature_fixture(%{
          key: "test3",
          project_id: project.id,
          archived_at: DateTime.utc_now(),
          feature_revisions: [
            %{
              value: %{
                value: "false",
                type: :boolean
              },
              created_by_id: user.id,
              updated_by_id: user.id
            }
          ]
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
    test "returns true if feature is stale", %{project: project, user: user} do
      feature =
        feature_fixture(%{
          key: "test",
          project_id: project.id,
          current_user_id: user.id
        })

      feature = %{feature | last_used_at: DateTime.utc_now() |> DateTime.add(-60 * 26, :hour)}
      assert Features.stale?(feature)
    end

    @tag :skip
    test "returns false if feature is not stale", %{project: project, user: user} do
      feature =
        feature_fixture(%{
          key: "test",
          project_id: project.id,
          current_user_id: user.id
        })

      feature = %{feature | last_used_at: DateTime.utc_now() |> DateTime.add(-3, :hour)}
      refute Features.stale?(feature)
    end
  end
end
