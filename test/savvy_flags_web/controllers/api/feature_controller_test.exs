defmodule SavvyFlagsWeb.Api.FeatureControllerTest do
  use SavvyFlagsWeb.ConnCase

  import SavvyFlags.SdkConnectionsFixtures
  import SavvyFlags.AccountsFixtures
  import SavvyFlags.FeaturesFixtures
  import SavvyFlags.ProjectsFixtures
  import SavvyFlags.EnvironmentsFixtures
  import SavvyFlags.AttributesFixtures

  setup do
    user = user_fixture()
    environment = environment_fixture()
    attribute_fixture(%{name: "email"})
    project = project_fixture()

    feature =
      feature_with_published_revision_fixture(%{
        current_user_id: user.id,
        key: "myapp:nav-v2",
        project_id: project.id,
        environments_enabled: [environment.id]
      })

    [revision] = feature.revisions

    rule_fixture(%{
      description: "Test",
      revision_id: revision.id,
      environment_id: environment.id,
      value: %{type: :boolean, value: "true"},
      conditions: [
        %{
          position: 1,
          attribute: "email",
          type: :match_regex,
          value: ".*\.gmail.com$"
        }
      ]
    })

    %{environment: environment, project: project}
  end

  describe "Plain mode" do
    setup ctx do
      sdk_connection =
        sdk_connection_fixture(%{
          name: "test-plain",
          mode: :plain,
          project_ids: [ctx.project.id],
          environment_id: ctx.environment.id
        })

      %{sdk_connection: sdk_connection}
    end

    test "must return error if requested with remote evaluated mode POST method", %{
      conn: conn,
      sdk_connection: sdk_connection
    } do
      conn = post(conn, ~p"/api/features/#{sdk_connection}")
      assert response = json_response(conn, 400)

      assert response["error"] ==
               "Plain SDK connection must use GET request to evaluate Feature flag locally"
    end

    test "must return feature with rules", %{
      conn: conn,
      sdk_connection: sdk_connection
    } do
      conn = get(conn, ~p"/api/features/#{sdk_connection}")
      assert response = json_response(conn, 200)

      assert response == %{
               "features" => %{
                 "myapp:nav-v2" => %{
                   "default_value" => "false",
                   "rules" => [
                     %{
                       "condition" => %{"email" => %{"match_regex" => ".*.gmail.com$"}},
                       "value" => "true"
                     }
                   ],
                   "type" => "boolean"
                 }
               }
             }
    end
  end

  describe "Remote evaluated mode" do
    setup ctx do
      sdk_connection =
        sdk_connection_fixture(%{
          name: "test-remote",
          mode: :remote_evaluated,
          project_ids: [ctx.project.id],
          environment_id: ctx.environment.id
        })

      %{sdk_connection: sdk_connection}
    end

    test "must return error if requested with plain mode GET method", %{
      conn: conn,
      sdk_connection: sdk_connection
    } do
      conn = get(conn, ~p"/api/features/#{sdk_connection}")
      assert response = json_response(conn, 400)

      assert response["error"] ==
               "Remote evaluated SDK connection must use POST request with attributes as body"
    end

    test "must return evalueated feature", %{
      conn: conn,
      sdk_connection: sdk_connection
    } do
      conn = post(conn, ~p"/api/features/#{sdk_connection}", %{})
      assert response = json_response(conn, 200)
      assert response == %{"features" => %{"myapp:nav-v2" => "false"}}
    end

    test "must return evalueted feature w/ payload", %{
      conn: conn,
      sdk_connection: sdk_connection
    } do
      conn =
        post(conn, ~p"/api/features/#{sdk_connection}", %{email: "example@gmail.com"})

      assert response = json_response(conn, 200)
      assert response == %{"features" => %{"myapp:nav-v2" => "true"}}
    end
  end

  describe "streaming" do
    setup ctx do
      sdk_connection =
        sdk_connection_fixture(%{
          name: "test-remote",
          mode: :remote_evaluated,
          project_ids: [ctx.project.id],
          environment_id: ctx.environment.id
        })

      %{sdk_connection: sdk_connection}
    end

    @tag :skip
    test "must stream events", %{
      conn: conn,
      sdk_connection: sdk_connection
    } do
      conn = get(conn, ~p"/api/features/#{sdk_connection}/stream?test=true")
      assert get_resp_header(conn, "content-type") == ["text/event-stream"]
    end
  end
end
