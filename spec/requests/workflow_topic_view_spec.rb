# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe "Workflow topic view", type: :request do
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[1], refresh_auto_groups: true) }
  fab!(:workflow) { Fabricate(:workflow, name: "Topic View Workflow") }
  fab!(:category, :category)
  fab!(:step_1) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: category.id,
      position: 1,
      name: "Triage",
    )
  end
  fab!(:option_accept) { Fabricate(:workflow_option, slug: "accept", name: "Accept") }
  fab!(:step_option) do
    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: option_accept.id,
      position: 1,
    )
  end
  fab!(:topic) { Fabricate(:topic, category: category, user: user) }
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
    category.set_permissions(everyone: :full, staff: :full)
    category.save!
    sign_in(user)
  end

  it "returns workflow metadata in topic view json" do
    get "#{topic.relative_url}.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body["workflow_name"]).to eq(workflow.name)
    expect(response.parsed_body["workflow_step_name"]).to eq(step_1.name)
    expect(response.parsed_body["workflow_step_actions"]).to be_present
  end
end
