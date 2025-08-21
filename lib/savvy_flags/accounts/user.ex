defmodule SavvyFlags.Accounts.User do
  use Ecto.Schema
  import SavvyFlags.Fields
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :reference}
  schema "users" do
    prefixed_reference :user
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :naive_datetime
    field :secret, :binary
    field :recovery_codes, {:array, :string}

    field :role, Ecto.Enum, values: [:owner, :admin, :member], default: :member
    field :full_access, :boolean

    many_to_many :features, SavvyFlags.Features.Feature,
      join_through: "user_features",
      on_replace: :delete

    many_to_many :projects, SavvyFlags.Projects.Project,
      join_through: "user_projects",
      on_replace: :delete

    many_to_many :environments, SavvyFlags.Environments.Environment,
      join_through: "user_environments",
      on_replace: :delete

    field :feature_ids, {:array, :integer}, virtual: true
    field :project_ids, {:array, :integer}, virtual: true
    field :environment_ids, {:array, :integer}, virtual: true

    field :environment_permissions, :integer, default: 0
    field :project_permissions, :integer, default: 0
    field :attribute_permissions, :integer, default: 0
    field :sdk_connection_permissions, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """

  def invitation_changeset(user, attrs) do
    registration_changeset(user, attrs, validate_email: true)
  end

  def changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [
      :email,
      :password,
      :secret,
      :recovery_codes,
      :role,
      :full_access,
      :environment_permissions,
      :project_permissions,
      :attribute_permissions,
      :sdk_connection_permissions
    ])
    |> validate_email(opts)
    |> reset_permissions()
  end

  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [
      :email,
      :password,
      :secret,
      :recovery_codes,
      :role,
      :full_access,
      :environment_permissions,
      :project_permissions,
      :attribute_permissions,
      :sdk_connection_permissions
    ])
    |> validate_email(opts)
    |> validate_password(opts)
    |> reset_permissions()
  end

  defp reset_permissions(changeset) do
    role = get_change(changeset, :role)

    if role in [:admin, :owner] do
      changeset
      |> put_change(:environment_permissions, 15)
      |> put_change(:project_permissions, 15)
      |> put_change(:attribute_permissions, 15)
      |> put_change(:sdk_connection_permissions, 15)
    else
      changeset
    end
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  @min_length_password Application.compile_env(:savvy_flags, :min_length_password, 12)

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: @min_length_password, max: 72)
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, SavvyFlags.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%SavvyFlags.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  def mfa_changeset(user, secret, recovery_codes) do
    user
    |> cast(%{secret: secret, recovery_codes: recovery_codes}, [:secret, :recovery_codes])
  end
end
