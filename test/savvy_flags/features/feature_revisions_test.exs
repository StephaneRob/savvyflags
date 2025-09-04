defmodule SavvyFlags.Features.FeatureRevisionsTest do
  alias SavvyFlags.Features.FeatureRule
  use SavvyFlags.DataCase, async: true

  alias SavvyFlags.Features
  alias SavvyFlags.Features.Feature
  alias SavvyFlags.Features.FeatureRevision
  alias SavvyFlags.Features.FeatureRevisions

  import SavvyFlags.AccountsFixtures
  import SavvyFlags.FeaturesFixtures
  import SavvyFlags.ProjectsFixtures
  import SavvyFlags.EnvironmentsFixtures

  setup do
    user = user_fixture()
    project = project_fixture()
    environment = environment_fixture()

    %{user: user, environment: environment, project: project}
  end

  describe "publish_revision/1" do
    test "must publish a feature revision", %{
      project: project,
      user: user
    } do
      feature =
        feature_fixture(project_id: project.id, current_user_id: user.id)

      assert {:ok, %{publish_revision: feature_revision}} =
               FeatureRevisions.publish_revision(feature.last_feature_revision)

      assert feature_revision.status == :published
    end

    test "must do nothing if already published", %{
      project: project,
      user: user
    } do
      feature =
        feature_with_published_revision_fixture(project_id: project.id, current_user_id: user.id)

      assert {:ok, %{publish_revision: feature_revision}} =
               FeatureRevisions.publish_revision(feature.last_feature_revision)

      assert feature_revision.status == :published
      assert feature_revision.id == feature.current_feature_revision.id
      assert feature_revision.revision_number == feature.current_feature_revision.revision_number
      assert feature_revision.updated_at == feature.current_feature_revision.updated_at
    end
  end

  describe "update_feature_with_revision/2" do
    test "must create revision w/ feature  update feature", %{
      project: project,
      environment: environment,
      user: user
    } do
      feature =
        feature_with_published_revision_fixture(project_id: project.id, current_user_id: user.id)

      feature_rule_fixture(%{
        description: "test feature rule",
        feature_revision_id: feature.last_feature_revision.id,
        environment_id: environment.id,
        value: %{
          value: "true",
          type: feature.last_feature_revision.value.type
        },
        conditions: [
          %{attribute: "id", type: :equal, value: "10"}
        ]
      })

      feature =
        SavvyFlags.Repo.preload(
          feature,
          Features.default_feature_preloads(),
          force: true
        )

      assert {:ok, %{feature_revision_updated: feature_revision_updated}} =
               FeatureRevisions.update_feature_revision(feature, user, %{
                 current_user_id: user.id,
                 value: %{
                   type: :boolean,
                   value: "false"
                 }
               })

      assert feature_revision_updated.revision_number == 2
      assert feature_revision_updated.status == :draft
      assert feature_revision_updated.value.value == "false"
    end
  end

  describe "create_feature_rule_with_revision/1" do
    test "must create revision w/ feature rule create a new feature rule", %{
      environment: environment,
      project: project,
      user: user
    } do
      feature =
        feature_with_published_revision_fixture(project_id: project.id, current_user_id: user.id)

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
            %{attribute: "id", type: :equal, value: "10"}
          ]
        })

      feature =
        SavvyFlags.Repo.preload(
          feature,
          Features.default_feature_preloads(),
          force: true
        )

      assert SavvyFlags.Repo.aggregate(FeatureRevision, :count, :id) == 1

      assert {:ok,
              %{
                feature: feature,
                feature_revision: feature_revision,
                feature_rule: new_feature_rule,
                feature_rules_revision: feature_rules_revision
              }} =
               FeatureRevisions.create_feature_rule_with_revision(feature, user, %{
                 "description" => "new rule",
                 "environment_id" => environment.id,
                 "value" => %{
                   "value" => "true",
                   "type" => :boolean
                 },
                 "conditions" => [
                   %{
                     "attribute" => "org_id",
                     "type" => :equal,
                     "value" => "20"
                   }
                 ]
               })

      assert SavvyFlags.Repo.aggregate(FeatureRevision, :count, :id) == 2
      assert SavvyFlags.Repo.aggregate(FeatureRule, :count, :id) == 3
      assert %FeatureRule{} = Map.get(feature_rules_revision, feature_rule.id)
      assert new_feature_rule.feature_revision_id == feature_revision.id
      assert new_feature_rule.description == "new rule"
      feature_revision = SavvyFlags.Repo.preload(feature_revision, :feature_rules)
      assert feature_revision.feature_rules |> Enum.count() == 2
      assert feature_revision.revision_number == 2
      assert feature_revision.id != feature.current_feature_revision.id
    end

    test "if feature draft must create feature rule w/o revision", %{
      environment: environment,
      user: user,
      project: project
    } do
      feature = feature_fixture(project_id: project.id, current_user_id: user.id)

      feature_rule_fixture(%{
        description: "test feature rule",
        feature_revision_id: feature.last_feature_revision.id,
        environment_id: environment.id,
        value: %{
          value: "true",
          type: feature.last_feature_revision.value.type
        },
        conditions: [
          %{attribute: "id", type: :equal, value: "10"}
        ]
      })

      feature =
        SavvyFlags.Repo.preload(
          feature,
          Features.default_feature_preloads(),
          force: true
        )

      assert SavvyFlags.Repo.aggregate(Feature, :count, :id) == 1
      assert SavvyFlags.Repo.aggregate(FeatureRule, :count, :id) == 1

      assert {:ok,
              %{
                feature: _,
                feature_revision: nil,
                feature_rules_revision: nil,
                feature_rule: new_feature_rule
              }} =
               FeatureRevisions.create_feature_rule_with_revision(feature, user, %{
                 "description" => "new rule",
                 "environment_id" => environment.id,
                 "value" => %{
                   "value" => "true",
                   "type" => :boolean
                 },
                 "conditions" => [
                   %{
                     "attribute" => "org_id",
                     "type" => :equal,
                     "value" => "20"
                   }
                 ]
               })

      assert SavvyFlags.Repo.aggregate(FeatureRule, :count, :id) == 2
      assert new_feature_rule.feature_revision_id == feature.last_feature_revision.id
    end
  end

  describe "update_feature_rule_with_revision/1" do
    test "must create revision w/ feature rule edit the corresponding feature rule", %{
      environment: environment,
      project: project,
      user: user
    } do
      feature =
        feature_with_published_revision_fixture(project_id: project.id, current_user_id: user.id)

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
            %{attribute: "id", type: :equal, value: "10"}
          ]
        })

      feature =
        SavvyFlags.Repo.preload(
          feature,
          Features.default_feature_preloads(),
          force: true
        )

      assert SavvyFlags.Repo.aggregate(FeatureRevision, :count, :id) == 1

      assert {:ok,
              %{
                feature: feature,
                feature_revision: feature_revision,
                feature_rule: new_feature_rule,
                feature_rules_revision: feature_rules_revision
              }} =
               FeatureRevisions.update_feature_rule_with_revision(feature_rule, feature, user, %{
                 "description" => "new rule",
                 "environment_id" => environment.id,
                 "value" => %{
                   "value" => "true",
                   "type" => :boolean
                 },
                 "conditions" => [
                   %{
                     "attribute" => "org_id",
                     "type" => :equal,
                     "value" => "20"
                   }
                 ]
               })

      assert SavvyFlags.Repo.aggregate(FeatureRevision, :count, :id) == 2
      assert SavvyFlags.Repo.aggregate(FeatureRule, :count, :id) == 2
      assert %FeatureRule{} = Map.get(feature_rules_revision, feature_rule.id)
      assert new_feature_rule.feature_revision_id == feature_revision.id
      assert new_feature_rule.description == "new rule"
      feature_revision = SavvyFlags.Repo.preload(feature_revision, :feature_rules)
      assert feature_revision.feature_rules |> Enum.count() == 1
      assert feature_revision.revision_number == 2
      assert feature_revision.id != feature.current_feature_revision.id
    end

    test "if feature draft must edit feature rule w/o revision", %{
      environment: environment,
      user: user,
      project: project
    } do
      feature = feature_fixture(project_id: project.id, current_user_id: user.id)

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
            %{attribute: "id", type: :equal, value: "10"}
          ]
        })

      feature =
        SavvyFlags.Repo.preload(
          feature,
          Features.default_feature_preloads(),
          force: true
        )

      assert SavvyFlags.Repo.aggregate(Feature, :count, :id) == 1
      assert SavvyFlags.Repo.aggregate(FeatureRule, :count, :id) == 1

      assert {:ok,
              %{
                feature: _,
                feature_revision: nil,
                feature_rules_revision: nil,
                feature_rule: new_feature_rule
              }} =
               FeatureRevisions.update_feature_rule_with_revision(feature_rule, feature, user, %{
                 "description" => "new rule",
                 "environment_id" => environment.id,
                 "value" => %{
                   "value" => "true",
                   "type" => :boolean
                 },
                 "conditions" => [
                   %{
                     "attribute" => "org_id",
                     "type" => :equal,
                     "value" => "20"
                   }
                 ]
               })

      assert SavvyFlags.Repo.aggregate(FeatureRule, :count, :id) == 1
      assert new_feature_rule.feature_revision_id == feature.last_feature_revision.id
    end
  end
end
