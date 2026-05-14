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

  it "deletes incoming and outgoing step options when destroying a workflow step" do
    category_3 = Fabricate(:category)
    step_3 =
      Fabricate(:workflow_step, workflow_id: workflow.id, category_id: category_3.id, position: 3)
    incoming_step_option =
      Fabricate(
        :workflow_step_option,
        workflow_step_id: step_2.id,
        workflow_option_id: option.id,
        target_step_id: step_1.id,
        position: 1,
      )
    unrelated_step_option =
      Fabricate(
        :workflow_step_option,
        workflow_step_id: step_2.id,
        workflow_option_id: option.id,
        target_step_id: step_3.id,
        position: 2,
      )
    outgoing_step_option_id = step_option_1.id
    incoming_step_option_id = incoming_step_option.id
    unrelated_step_option_id = unrelated_step_option.id

    delete "/admin/plugins/discourse-workflow/workflow_steps/#{step_1.id}.json"

    expect(response.status).to eq(204)
    expect(DiscourseWorkflow::WorkflowStep.exists?(step_1.id)).to eq(false)
    expect(DiscourseWorkflow::WorkflowStepOption.exists?(outgoing_step_option_id)).to eq(false)
    expect(DiscourseWorkflow::WorkflowStepOption.exists?(incoming_step_option_id)).to eq(false)
    expect(DiscourseWorkflow::WorkflowStepOption.exists?(unrelated_step_option_id)).to eq(true)
  end

  it "reorders a workflow step and displaced step atomically" do
    put "/admin/plugins/discourse-workflow/workflow_steps/#{step_1.id}/reorder.json",
        params: {
          workflow_step: {
            category_id: category_2.id,
            position: 2,
          },
        }

    expect(response.status).to eq(200)
    expect(step_1.reload.category_id).to eq(category_2.id)
    expect(step_1.position).to eq(2)
    expect(step_2.reload.category_id).to eq(category_2.id)
    expect(step_2.position).to eq(1)
  end

  it "rolls back displaced step position when reorder fails" do
    allow_any_instance_of(DiscourseWorkflow::WorkflowStep).to receive(
      :update!,
    ).and_wrap_original do |method, *args|
      if method.receiver.id == step_1.id
        method.receiver.errors.add(:base, "forced failure")
        raise ActiveRecord::RecordInvalid.new(method.receiver)
      end

      method.call(*args)
    end

    put "/admin/plugins/discourse-workflow/workflow_steps/#{step_1.id}/reorder.json",
        params: {
          workflow_step: {
            category_id: category_2.id,
            position: 2,
          },
        }

    expect(response.status).to eq(422)
    expect(step_1.reload.category_id).to eq(category_1.id)
    expect(step_1.position).to eq(1)
    expect(step_2.reload.category_id).to eq(category_2.id)
    expect(step_2.position).to eq(2)
  end
end
