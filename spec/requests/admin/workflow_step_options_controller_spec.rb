# frozen_string_literal: true

require_relative "../../plugin_helper"

describe DiscourseWorkflow::Admin::WorkflowStepOptionsController do
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
  fab!(:existing_option) { Fabricate(:workflow_option, slug: "start") }
  fab!(:new_option) { Fabricate(:workflow_option, slug: "next") }
  fab!(:step_option) do
    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: existing_option.id,
      target_step_id: step_2.id,
      position: 1,
    )
  end

  before { sign_in(admin) }

  it "creates a step option with next position when position is omitted" do
    expect do
      post "/admin/plugins/discourse-workflow/workflow_step_options.json",
           params: {
             workflow_step_option: {
               workflow_step_id: step_1.id,
               workflow_option_id: new_option.id,
               target_step_id: step_2.id,
             },
           }
    end.to change { DiscourseWorkflow::WorkflowStepOption.count }.by(1)

    expect(response.status).to eq(201)
    expect(DiscourseWorkflow::WorkflowStepOption.order(:id).last.position).to eq(
      2,
    )
  end
end
