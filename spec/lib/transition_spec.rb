# frozen_string_literal: true
require_relative '../plugin_helper'

describe ::DiscourseWorkflow::Transition do

  fab!(:workflow) {
    Fabricate(:workflow, name: "Test Workflow", description: "Test Workflow Description")
  }
  fab!(:step_1) {
    Fabricate(:workflow_step, workflow_id: workflow.id, name: "Step 1", description: "Step 1 Description")
  }
  fab!(:step_2) {
    Fabricate(:workflow_step, workflow_id: workflow.id, name: "Step 2", description: "Step 2 Description")
  }

  fab!(:option_1, :workflow_option)

  fab!(:step_option_1) {
    Fabricate(:workflow_step_option, workflow_step_id: step_1.id, workflow_option_id: option_1.id, target_step_id: step_2.id)
  }

  fab!(:topic)

  fab!(:workflow_state) {
    Fabricate(:workflow_state, topic_id: topic.id, workflow_id: workflow.id, workflow_step_id: step_1.id)
  }

  fab!(:user)

  fab!(:transition) {
    DiscourseWorkflow::Transition.new
  }

  it "creates an audit log entry" do
    expect { transition.transition(user.id, topic, option_1.slug) }.to change { ::DiscourseWorkflow::WorkflowAuditLog.count }.by(1)
  end

  it "updates the topic with a small action Post" do
    expect { transition.transition(user.id, topic, option_1.slug) }.to change { ::Post.where(topic_id: topic.id).count }.by(1)
  end
end
