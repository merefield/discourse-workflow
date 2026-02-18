# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe DiscourseWorkflow::WorkflowActionController, type: :request do
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[1], refresh_auto_groups: true) }
  fab!(:workflow) { Fabricate(:workflow, name: "Cooldown Workflow") }
  fab!(:category_1, :category)
  fab!(:category_2, :category)
  fab!(:step_1) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: category_1.id,
      position: 1,
      name: "Step A",
    )
  end
  fab!(:step_2) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: category_2.id,
      position: 2,
      name: "Step B",
    )
  end
  fab!(:next_option) { Fabricate(:workflow_option, slug: "next", name: "Next") }
  fab!(:step_1_option) do
    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: next_option.id,
      target_step_id: step_2.id,
      position: 1,
    )
  end
  fab!(:step_2_option) do
    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_2.id,
      workflow_option_id: next_option.id,
      target_step_id: step_1.id,
      position: 1,
    )
  end
  fab!(:topic) { Fabricate(:topic, category: category_1, user: user) }
  fab!(:workflow_state) do
    Fabricate(
      :workflow_state,
      topic_id: topic.id,
      workflow_id: workflow.id,
      workflow_step_id: step_1.id,
    )
  end

  before do
    SiteSetting.workflow_enabled = true
    DiscourseWorkflow::Transition.any_instance.stubs(:transition).returns(true)
    category_1.set_permissions(everyone: :full, staff: :full)
    category_2.set_permissions(everyone: :full, staff: :full)
    category_1.save!
    category_2.save!
    sign_in(user)
    Discourse.redis.del("discourse-workflow-transition-#{user.id}-#{topic.id}")
  end

  it "blocks immediate repeated transitions for the same user and topic" do
    post "/discourse-workflow/act/#{topic.id}.json", params: { option: "next" }
    expect(response.status).to eq(200)
    expect(response.parsed_body["success"]).to eq("OK")

    expect do
      post "/discourse-workflow/act/#{topic.id}.json", params: { option: "next" }
    end.not_to change { DiscourseWorkflow::WorkflowAuditLog.count }

    expect(response.parsed_body["failed"]).to eq("FAILED")
  end
end
