# frozen_string_literal: true

require_relative "../plugin_helper"

describe "Workflow topic lifecycle behavior" do
  fab!(:workflow) do
    Fabricate(:workflow, name: "Disabled Workflow", enabled: false)
  end
  fab!(:start_category, :category)
  fab!(:mid_category, :category)
  fab!(:step_1) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: start_category.id,
      position: 1,
    )
  end
  fab!(:step_2) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: mid_category.id,
      position: 2,
    )
  end

  it "does not initialize workflow_state for topics when workflow is disabled" do
    SiteSetting.workflow_enabled = true
    topic = Fabricate(:topic, category: start_category)
    DiscourseWorkflow::WorkflowState.where(topic_id: topic.id).delete_all

    expect do
      DiscourseEvent.trigger(:topic_created, topic, {})
    end.not_to change { DiscourseWorkflow::WorkflowState.count }
  end

  it "allows creating a topic in a later step category when workflow is disabled" do
    topic = Fabricate.build(:topic, category: mid_category)

    expect(topic).to be_valid
  end
end
