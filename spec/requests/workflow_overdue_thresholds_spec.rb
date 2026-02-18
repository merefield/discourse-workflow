# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe "Workflow overdue thresholds", type: :request do
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[1], refresh_auto_groups: true) }

  fab!(:workflow_global_default) do
    Fabricate(:workflow, name: "Global Default Workflow", overdue_days: nil)
  end
  fab!(:workflow_override) do
    Fabricate(:workflow, name: "Workflow Override", overdue_days: 5)
  end
  fab!(:workflow_step_override) do
    Fabricate(:workflow, name: "Step Override", overdue_days: 10)
  end
  fab!(:workflow_disabled) do
    Fabricate(:workflow, name: "Disabled Overdue", overdue_days: 0)
  end

  fab!(:category_global_default, :category)
  fab!(:category_workflow_override, :category)
  fab!(:category_step_override, :category)
  fab!(:category_disabled, :category)

  fab!(:step_global_default) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow_global_default.id,
      category_id: category_global_default.id,
      position: 1,
      overdue_days: nil,
    )
  end
  fab!(:step_workflow_override) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow_override.id,
      category_id: category_workflow_override.id,
      position: 1,
      overdue_days: nil,
    )
  end
  fab!(:step_step_override) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow_step_override.id,
      category_id: category_step_override.id,
      position: 1,
      overdue_days: 2,
    )
  end
  fab!(:step_disabled) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow_disabled.id,
      category_id: category_disabled.id,
      position: 1,
      overdue_days: nil,
    )
  end

  fab!(:topic_global_default) { Fabricate(:topic_with_op, category: category_global_default, user: user) }
  fab!(:topic_workflow_override) { Fabricate(:topic_with_op, category: category_workflow_override, user: user) }
  fab!(:topic_step_override) { Fabricate(:topic_with_op, category: category_step_override, user: user) }
  fab!(:topic_disabled) { Fabricate(:topic_with_op, category: category_disabled, user: user) }

  fab!(:state_global_default) do
    Fabricate(
      :workflow_state,
      topic_id: topic_global_default.id,
      workflow_id: workflow_global_default.id,
      workflow_step_id: step_global_default.id,
    )
  end
  fab!(:state_workflow_override) do
    Fabricate(
      :workflow_state,
      topic_id: topic_workflow_override.id,
      workflow_id: workflow_override.id,
      workflow_step_id: step_workflow_override.id,
    )
  end
  fab!(:state_step_override) do
    Fabricate(
      :workflow_state,
      topic_id: topic_step_override.id,
      workflow_id: workflow_step_override.id,
      workflow_step_id: step_step_override.id,
    )
  end
  fab!(:state_disabled) do
    Fabricate(
      :workflow_state,
      topic_id: topic_disabled.id,
      workflow_id: workflow_disabled.id,
      workflow_step_id: step_disabled.id,
    )
  end

  before do
    SiteSetting.workflow_enabled = true
    SiteSetting.workflow_overdue_days_default = 3
    sign_in(user)

    [category_global_default,
     category_workflow_override,
     category_step_override,
     category_disabled].each do |category|
      category.set_permissions(everyone: :full, staff: :full)
      category.save!
    end

    state_global_default.update_columns(updated_at: 4.days.ago)
    state_workflow_override.update_columns(updated_at: 4.days.ago)
    state_step_override.update_columns(updated_at: 3.days.ago)
    state_disabled.update_columns(updated_at: 30.days.ago)
  end

  it "uses step then workflow then global overdue thresholds when overdue=1 filter is enabled" do
    get "/workflow.json", params: { overdue: "1" }

    topic_ids = response.parsed_body.dig("topic_list", "topics").map { |t| t["id"] }

    expect(topic_ids).to include(topic_global_default.id)
    expect(topic_ids).to include(topic_step_override.id)
    expect(topic_ids).not_to include(topic_workflow_override.id)
    expect(topic_ids).not_to include(topic_disabled.id)
  end

  it "marks overdue state per topic in workflow list payload" do
    get "/workflow.json"

    topics = response.parsed_body.dig("topic_list", "topics")
    topic_by_id = topics.index_by { |topic| topic["id"] }

    expect(topic_by_id[topic_global_default.id]["workflow_overdue"]).to eq(true)
    expect(topic_by_id[topic_workflow_override.id]["workflow_overdue"]).to eq(false)
    expect(topic_by_id[topic_step_override.id]["workflow_overdue"]).to eq(true)
    expect(topic_by_id[topic_disabled.id]["workflow_overdue"]).to eq(false)
  end
end
