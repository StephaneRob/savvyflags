defmodule SavvyFlagsWeb.FeatureLive.Components.Revision do
  use SavvyFlagsWeb, :html
  alias SavvyFlags.Features.Revision

  attr :revision, Revision, required: true

  def revision(assigns) do
    ~H"""
    <.badge value={"v#{@revision.revision_number}"} variant="code" />
    <.badge
      :if={@revision.status == :draft}
      value={"#{@revision.status}"}
      variant="warning"
    />
    <.badge
      :if={@revision.status == :unpublished}
      value={"#{@revision.status}"}
    />
    <.badge
      :if={@revision.status == :published}
      value={"#{@revision.status}"}
      variant="success"
    />
    """
  end
end
