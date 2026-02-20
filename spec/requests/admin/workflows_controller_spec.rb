# frozen_string_literal: true

require_relative "../../plugin_helper"

describe DiscourseWorkflow::Admin::WorkflowsController do
  fab!(:admin)
  fab!(:workflow) { Fabricate(:workflow, name: "Controller Workflow") }
  fab!(:category_1, :category)
  fab!(:category_2, :category)
  fab!(:step_1) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: category_1.id,
      position: 1,
    )
  end
  fab!(:step_2) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: category_2.id,
      position: 2,
    )
  end

  before { sign_in(admin) }

  it "serializes kanban compatibility for incompatible workflows" do
    get "/admin/plugins/discourse-workflow/workflows.json"

    expect(response.status).to eq(200)
    payload = response.parsed_body["workflows"].find { |w| w["id"] == workflow.id }
    expect(payload["kanban_compatible"]).to eq(false)
  end

  it "serializes kanban compatibility for compatible workflows" do
    option = Fabricate(:workflow_option, slug: "next", name: "Next")
    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: option.id,
      target_step_id: step_2.id,
    )

    get "/admin/plugins/discourse-workflow/workflows.json"

    expect(response.status).to eq(200)
    payload = response.parsed_body["workflows"].find { |w| w["id"] == workflow.id }
    expect(payload["kanban_compatible"]).to eq(true)
  end
end
