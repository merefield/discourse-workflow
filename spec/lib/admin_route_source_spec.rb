# frozen_string_literal: true

require_relative "../plugin_helper"

describe "Admin workflow route source contracts" do
  it "loads step options from the canonical parent route key" do
    route_path =
      File.expand_path(
        "../../assets/javascripts/discourse/admin/routes/admin-plugins-show-discourse-workflow-workflows-steps-options.js",
        __dir__,
      )
    source = File.read(route_path)

    expect(source).to include(
      '"adminPlugins.show.discourse-workflow-workflows-steps"',
    )
    expect(source).not_to include(
      '"admin.plugins.show.discourse-workflow.workflows.steps"',
    )
  end

  it "derives workflow id in setupController without nested router path traversal" do
    route_path =
      File.expand_path(
        "../../assets/javascripts/discourse/admin/routes/admin-plugins-show-discourse-workflow-workflows-steps-options-edit.js",
        __dir__,
      )
    source = File.read(route_path)

    expect(source).to include("model.workflow_id")
    expect(source).not_to include("this.router.currentRoute.parent.parent")
  end
end
