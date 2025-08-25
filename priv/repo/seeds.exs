alias SavvyFlags.{Accounts, Repo, Environments, Projects, Features, Attributes, SdkConnections}
SavvyFlags.setup()

if System.get_env("SEED") do
  environments = Environments.list_environments()
  projects = Projects.list_projects()

  {:ok, _} =
    %{
      email: "mail@example.com",
      password: "azerty",
      role: :admin,
      environment_permissions: 0b1111,
      project_permissions: 0b1111,
      attribute_permissions: 0b1111,
      sdk_connection_permissions: 0b1111
    }
    |> Accounts.register_user()

  {:ok, _} =
    Features.create_feature(%{
      archived_at: DateTime.utc_now(),
      key: "myapp:nav_color",
      description: "Change navbar color",
      project_id: List.first(projects).id,
      default_value: %{type: :boolean, value: "false"}
    })

  email_attribute = Repo.get_by(Attributes.Attribute, name: "email")

  {:ok, feature} =
    Features.create_feature(%{
      key: "myapp:change_cta_button",
      description: "Change wording of the CTA Signup",
      project_id: List.first(projects).id,
      environments_enabled: [List.first(environments).id],
      default_value: %{type: :boolean, value: "false"}
    })

  {:ok, _} =
    Features.create_feature_rule(%{
      feature_id: feature.id,
      description: "Activate for gmail users",
      value: %{type: :boolean, value: "true"},
      environment_id: List.first(environments).id,
      feature_rule_conditions: [
        %{
          position: 1,
          attribute_id: email_attribute.id,
          type: :match_regex,
          value: ".*\.example.com$"
        }
      ]
    })

  {:ok, feature2} =
    Features.create_feature(%{
      key: "myapp:color_nav",
      description: "AB test nav color by default red",
      project_id: List.first(projects).id,
      default_value: %{type: :string, value: "red"}
    })

  {:ok, _} =
    Features.create_feature_rule(%{
      feature_id: feature2.id,
      description: "Activate for example users",
      value: %{type: :string, value: "green"},
      environment_id: List.first(environments).id,
      feature_rule_conditions: [
        %{
          position: 1,
          attribute_id: email_attribute.id,
          type: :match_regex,
          value: ".*\.example.com$"
        }
      ]
    })

  {:ok, _} =
    Features.create_feature(%{
      key: "myapp:new_profile",
      description: "Rollout our new profile page",
      project_id: List.last(projects).id,
      default_value: %{type: :boolean, value: "false"}
    })

  {:ok, _} =
    SdkConnections.create_sdk_connection(%{
      name: "Production",
      project_ids: [
        List.first(projects).id
      ],
      environment_id: List.first(environments).id
    })

  {:ok, _} =
    SdkConnections.create_sdk_connection(%{
      name: "Production remote",
      project_ids: [
        List.first(projects).id
      ],
      mode: :remote_evaluated,
      environment_id: List.first(environments).id
    })

  {:ok, u1} =
    %{
      email: "mail+1@example.com",
      password: "azerty",
      role: :member,
      environment_permissions: 0b1111,
      project_permissions: 0b1111,
      attribute_permissions: 0b1111,
      sdk_connection_permissions: 0b1111
    }
    |> Accounts.register_user()

  u1
  |> Repo.preload([:projects, :environments, :features])
  |> Accounts.update_user(%{
    project_ids: [List.first(projects).id],
    environment_ids: [List.first(environments).id]
  })

  {:ok, u2} =
    %{
      email: "mail+2@example.com",
      password: "azerty",
      role: :member,
      environment_permissions: 0b0001,
      project_permissions: 0b0001,
      attribute_permissions: 0b0001,
      sdk_connection_permissions: 0b0001
    }
    |> Accounts.register_user()

  u2
  |> Repo.preload([:projects, :environments, :features])
  |> Accounts.update_user(%{
    feature_ids: [feature.id]
  })
end
