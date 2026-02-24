# frozen_string_literal: true

require_relative "../plugin_helper"

describe DiscourseWorkflow::Stats do
  fab!(:workflow) { Fabricate(:workflow, name: "Stats Workflow") }
  fab!(:category_1, :category)
  fab!(:category_2, :category)
  fab!(:step_1) do
    Fabricate(:workflow_step, workflow_id: workflow.id, category_id: category_1.id, position: 1)
  end
  fab!(:step_2) do
    Fabricate(:workflow_step, workflow_id: workflow.id, category_id: category_2.id, position: 2)
  end
  fab!(:topic_1) { Fabricate(:topic, category: category_1) }
  fab!(:topic_2) { Fabricate(:topic, category: category_1) }
  fab!(:state_1) do
    Fabricate(
      :workflow_state,
      topic_id: topic_1.id,
      workflow_id: workflow.id,
      workflow_step_id: step_1.id,
    )
  end
  fab!(:state_2) do
    Fabricate(
      :workflow_state,
      topic_id: topic_2.id,
      workflow_id: workflow.id,
      workflow_step_id: step_2.id,
    )
  end

  it "calculates daily counts per workflow step from workflow states" do
    SiteSetting.workflow_enabled = true

    expect do described_class.new.calculate_daily_stats end.to change {
      DiscourseWorkflow::WorkflowStat.count
    }.by(2)
  end

  it "ignores corrupted states with null workflow_id or workflow_step_id" do
    SiteSetting.workflow_enabled = true

    state_1.update_columns(workflow_id: nil)
    state_2.update_columns(workflow_step_id: nil)

    valid_topic = Fabricate(:topic, category: category_1)
    Fabricate(
      :workflow_state,
      topic_id: valid_topic.id,
      workflow_id: workflow.id,
      workflow_step_id: step_1.id,
    )

    described_class.new.calculate_daily_stats

    today_stats = DiscourseWorkflow::WorkflowStat.where(cob_date: Date.current)
    expect(today_stats.count).to eq(1)
    expect(today_stats.first.workflow_id).to eq(workflow.id)
    expect(today_stats.first.workflow_step_id).to eq(step_1.id)
    expect(today_stats.first.count).to eq(1)
  end
end
