# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe "Workflow list filters", type: :request do
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[1], refresh_auto_groups: true) }
  fab!(:workflow) { Fabricate(:workflow, name: "Filtered Workflow") }
  fab!(:category_a, :category)
  fab!(:category_b, :category)
  fab!(:step_1) do
    Fabricate(:workflow_step, workflow_id: workflow.id, category_id: category_a.id, position: 1)
  end
  fab!(:step_2) do
    Fabricate(:workflow_step, workflow_id: workflow.id, category_id: category_b.id, position: 2)
  end
  fab!(:next_option) { Fabricate(:workflow_option, slug: "next", name: "Next") }
  fab!(:step_transition) do
    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: next_option.id,
      target_step_id: step_2.id,
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

  it "serializes kanban metadata when the visible list is a single compatible workflow" do
    get "/workflow.json"

    topic_list = response.parsed_body["topic_list"]
    steps = topic_list["workflow_kanban_steps"]
    step_positions = topic_list["workflow_kanban_steps"].map { |step| step["position"] }
    steps_by_position = steps.index_by { |step| step["position"] }
    transitions =
      topic_list["workflow_kanban_transitions"].map do |transition|
        [transition["from_position"], transition["to_position"], transition["option_slug"]]
      end
    topics_by_id = topic_list["topics"].index_by { |topic| topic["id"] }

    expect(topic_list["workflow_kanban_compatible"]).to eq(true)
    expect(topic_list["workflow_kanban_workflow_name"]).to eq(workflow.name)
    expect(topic_list["workflow_kanban_show_tags"]).to eq(true)
    expect(step_positions).to eq([1, 2])
    expect(steps_by_position[1]["category_color"]).to eq(category_a.color)
    expect(steps_by_position[2]["category_color"]).to eq(category_b.color)
    expect(transitions).to contain_exactly([1, 2, "next"])
    expect(topics_by_id[topic_a.id]["workflow_can_act"]).to eq(true)
    expect(topics_by_id[topic_b.id]["workflow_can_act"]).to eq(false)
  end

  it "serializes workflow_kanban_show_tags false when disabled on the workflow" do
    workflow.update!(show_kanban_tags: false)

    get "/workflow.json"

    topic_list = response.parsed_body["topic_list"]
    expect(topic_list["workflow_kanban_show_tags"]).to eq(false)
  end

  it "does not mark kanban compatibility when multiple workflows are visible" do
    other_workflow = Fabricate(:workflow, name: "Secondary Workflow")
    other_step =
      Fabricate(
        :workflow_step,
        workflow_id: other_workflow.id,
        category_id: category_a.id,
        position: 1,
      )
    other_topic = Fabricate(:topic, category: category_a)
    Fabricate(
      :workflow_state,
      topic_id: other_topic.id,
      workflow_id: other_workflow.id,
      workflow_step_id: other_step.id,
    )

    get "/workflow.json"

    topic_list = response.parsed_body["topic_list"]
    expect(topic_list["workflow_kanban_compatible"]).to eq(false)
    expect(topic_list["workflow_kanban_workflow_name"]).to be_nil
    expect(topic_list["workflow_kanban_steps"]).to eq([])
    expect(topic_list["workflow_kanban_transitions"]).to eq([])
  end

  it "does not materialize workflow topic ids when combining quick filters" do
    state_a.update_columns(updated_at: 5.days.ago)

    workflow_state_topic_id_plucks =
      track_sql_queries do
        get "/workflow.json",
            params: {
              my_categories: "1",
              overdue: "1",
              workflow_step_position: "1",
            }
      end.select do |query|
        query.match?(/SELECT\s+"workflow_states"\."topic_id"/) &&
          query.include?('FROM "workflow_states"')
      end

    expect(response.status).to eq(200)
    expect(workflow_state_topic_id_plucks).to eq([])
  end
end
