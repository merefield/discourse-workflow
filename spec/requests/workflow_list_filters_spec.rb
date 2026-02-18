# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe "Workflow list filters", type: :request do
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[1], refresh_auto_groups: true) }
  fab!(:workflow) { Fabricate(:workflow, name: "Filtered Workflow") }
  fab!(:category_a, :category)
  fab!(:category_b, :category)
  fab!(:step_1) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: category_a.id,
      position: 1,
    )
  end
  fab!(:step_2) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: category_b.id,
      position: 2,
    )
  end
  fab!(:topic_a) { Fabricate(:topic, category: category_a) }
  fab!(:topic_b) { Fabricate(:topic, category: category_a) }
  fab!(:state_a) do
    Fabricate(
      :workflow_state,
      topic_id: topic_a.id,
      workflow_id: workflow.id,
      workflow_step_id: step_1.id,
    )
  end
  fab!(:state_b) do
    Fabricate(
      :workflow_state,
      topic_id: topic_b.id,
      workflow_id: workflow.id,
      workflow_step_id: step_2.id,
    )
  end
  before do
    SiteSetting.workflow_enabled = true
    sign_in(user)

    category_a.set_permissions(everyone: :full, staff: :full)
    category_b.set_permissions(everyone: :readonly, staff: :full)
    category_a.save!
    category_b.save!

    topic_b.update_columns(category_id: category_b.id)
  end

  it "filters to categories where the current user can create topics" do
    get "/workflow.json", params: { my_categories: "1" }

    topic_ids = response.parsed_body.dig("topic_list", "topics").map { |t| t["id"] }
    expect(topic_ids).to include(topic_a.id)
    expect(topic_ids).not_to include(topic_b.id)
  end

  it "filters workflow topics by overdue days in step" do
    state_a.update_columns(updated_at: 5.days.ago)

    get "/workflow.json", params: { overdue_days: "3" }

    topic_ids = response.parsed_body.dig("topic_list", "topics").map { |t| t["id"] }
    expect(topic_ids).to include(topic_a.id)
    expect(topic_ids).not_to include(topic_b.id)
  end

  it "filters workflow topics by workflow step position" do
    get "/workflow.json", params: { workflow_step_position: "2" }

    topic_ids = response.parsed_body.dig("topic_list", "topics").map { |t| t["id"] }
    expect(topic_ids).to include(topic_b.id)
    expect(topic_ids).not_to include(topic_a.id)
  end
end
