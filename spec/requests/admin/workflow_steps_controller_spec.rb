# frozen_string_literal: true

require_relative "../../plugin_helper"

describe DiscourseWorkflow::Admin::WorkflowStepsController do
  fab!(:admin)
  fab!(:workflow) { Fabricate(:workflow, name: "Workflow Steps Controller Workflow") }
  fab!(:category_1, :category)
  fab!(:category_2, :category)
  fab!(:option) { Fabricate(:workflow_option, slug: "next-step") }
  fab!(:step_1) do
    Fabricate(:workflow_step, workflow_id: workflow.id, category_id: category_1.id, position: 1)
  end
  fab!(:step_2) do
    Fabricate(:workflow_step, workflow_id: workflow.id, category_id: category_2.id, position: 2)
  end
  fab!(:step_option_1) do
    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: option.id,
      target_step_id: step_2.id,
      position: 1,
    )
  end

  before { sign_in(admin) }

  it "does not add per-step queries when listing workflow steps" do
    get "/admin/plugins/discourse-workflow/workflows/#{workflow.id}/workflow_steps.json"
    base_query_count =
      track_sql_queries do
        get "/admin/plugins/discourse-workflow/workflows/#{workflow.id}/workflow_steps.json"
        expect(response.status).to eq(200)
      end.count

    5.times do |index|
      extra_category = Fabricate(:category)
      extra_step =
        Fabricate(
          :workflow_step,
          workflow_id: workflow.id,
          category_id: extra_category.id,
          position: index + 3,
        )
      Fabricate(
        :workflow_step_option,
        workflow_step_id: extra_step.id,
        workflow_option_id: option.id,
        target_step_id: step_1.id,
        position: 1,
      )
    end

    get "/admin/plugins/discourse-workflow/workflows/#{workflow.id}/workflow_steps.json"
    expanded_query_count =
      track_sql_queries do
        get "/admin/plugins/discourse-workflow/workflows/#{workflow.id}/workflow_steps.json"
        expect(response.status).to eq(200)
      end.count

    expect(expanded_query_count).to be <= base_query_count + 2
  end
end
