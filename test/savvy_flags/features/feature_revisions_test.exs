defmodule SavvyFlags.Features.RevisionsTest do
  alias SavvyFlags.Features.Rule
  use SavvyFlags.DataCase, async: true

  alias SavvyFlags.Features
  alias SavvyFlags.Features.Feature
  alias SavvyFlags.Features.Revision
  alias SavvyFlags.Features.Revisions

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

      assert {:ok, %{publish_revision: revision}} =
               Revisions.publish_revision(feature.last_revision)

      assert revision.status == :published
    end

    test "must do nothing if already published", %{
      project: project,
      user: user
    } do
      feature =
        feature_with_published_revision_fixture(project_id: project.id, current_user_id: user.id)

      assert {:ok, %{publish_revision: revision}} =
               Revisions.publish_revision(feature.last_revision)

      assert revision.status == :published
      assert revision.id == feature.current_revision.id
      assert revision.revision_number == feature.current_revision.revision_number
      assert revision.updated_at == feature.current_revision.updated_at
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

      rule_fixture(%{
        description: "test feature rule",
        revision_id: feature.last_revision.id,
        environment_id: environment.id,
        value: %{
          value: "true",
          type: feature.last_revision.value.type
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

      assert {:ok, %{revision_updated: revision_updated}} =
               Revisions.update_revision(feature, user, %{
                 current_user_id: user.id,
                 value: %{
                   type: :boolean,
                   value: "false"
                 }
               })

      assert revision_updated.revision_number == 2
      assert revision_updated.status == :draft
      assert revision_updated.value.value == "false"
    end
  end

  describe "create_rule_with_revision/1" do
    test "must create revision w/ feature rule create a new feature rule", %{
      environment: environment,
      project: project,
      user: user
    } do
      feature =
        feature_with_published_revision_fixture(project_id: project.id, current_user_id: user.id)

      rule =
        rule_fixture(%{
          description: "test feature rule",
          revision_id: feature.last_revision.id,
          environment_id: environment.id,
          value: %{
            value: "true",
            type: feature.last_revision.value.type
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

      assert SavvyFlags.Repo.aggregate(Revision, :count, :id) == 1

      assert {:ok,
              %{
                feature: feature,
                revision: revision,
                rule: new_rule,
                rules_revision: rules_revision
              }} =
               Revisions.create_rule_with_revision(feature, user, %{
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

      assert SavvyFlags.Repo.aggregate(Revision, :count, :id) == 2
      assert SavvyFlags.Repo.aggregate(Rule, :count, :id) == 3
      assert %Rule{} = Map.get(rules_revision, rule.id)
      assert new_rule.revision_id == revision.id
      assert new_rule.description == "new rule"
      revision = SavvyFlags.Repo.preload(revision, :rules)
      assert revision.rules |> Enum.count() == 2
      assert revision.revision_number == 2
      assert revision.id != feature.current_revision.id
    end

    test "if feature draft must create feature rule w/o revision", %{
      environment: environment,
      user: user,
      project: project
    } do
      feature = feature_fixture(project_id: project.id, current_user_id: user.id)

      rule_fixture(%{
        description: "test feature rule",
        revision_id: feature.last_revision.id,
        environment_id: environment.id,
        value: %{
          value: "true",
          type: feature.last_revision.value.type
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
      assert SavvyFlags.Repo.aggregate(Rule, :count, :id) == 1

      assert {:ok,
              %{
                feature: _,
                revision: nil,
                rules_revision: nil,
                rule: new_rule
              }} =
               Revisions.create_rule_with_revision(feature, user, %{
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

      assert SavvyFlags.Repo.aggregate(Rule, :count, :id) == 2
      assert new_rule.revision_id == feature.last_revision.id
    end
  end

  describe "update_rule_with_revision/1" do
    test "must create revision w/ feature rule edit the corresponding feature rule", %{
      environment: environment,
      project: project,
      user: user
    } do
      feature =
        feature_with_published_revision_fixture(project_id: project.id, current_user_id: user.id)

      rule =
        rule_fixture(%{
          description: "test feature rule",
          revision_id: feature.last_revision.id,
          environment_id: environment.id,
          value: %{
            value: "true",
            type: feature.last_revision.value.type
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

      assert SavvyFlags.Repo.aggregate(Revision, :count, :id) == 1

      assert {:ok,
              %{
                feature: feature,
                revision: revision,
                rule: new_rule,
                rules_revision: rules_revision
              }} =
               Revisions.update_rule_with_revision(rule, feature, user, %{
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

      assert SavvyFlags.Repo.aggregate(Revision, :count, :id) == 2
      assert SavvyFlags.Repo.aggregate(Rule, :count, :id) == 2
      assert %Rule{} = Map.get(rules_revision, rule.id)
      assert new_rule.revision_id == revision.id
      assert new_rule.description == "new rule"
      revision = SavvyFlags.Repo.preload(revision, :rules)
      assert revision.rules |> Enum.count() == 1
      assert revision.revision_number == 2
      assert revision.id != feature.current_revision.id
    end

    test "if feature draft must edit feature rule w/o revision", %{
      environment: environment,
      user: user,
      project: project
    } do
      feature = feature_fixture(project_id: project.id, current_user_id: user.id)

      rule =
        rule_fixture(%{
          description: "test feature rule",
          revision_id: feature.last_revision.id,
          environment_id: environment.id,
          value: %{
            value: "true",
            type: feature.last_revision.value.type
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
      assert SavvyFlags.Repo.aggregate(Rule, :count, :id) == 1

      assert {:ok,
              %{
                feature: _,
                revision: nil,
                rules_revision: nil,
                rule: new_rule
              }} =
               Revisions.update_rule_with_revision(rule, feature, user, %{
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

      assert SavvyFlags.Repo.aggregate(Rule, :count, :id) == 1
      assert new_rule.revision_id == feature.last_revision.id
    end
  end
end
