# frozen_string_literal: true

RSpec.describe "Workflow topic banner", type: :system do
  fab!(:actor, :user)
  fab!(:viewer, :user)
  fab!(:actor_group, :group)
  fab!(:workflow) { Fabricate(:workflow, name: "Topic Banner Workflow") }
  fab!(:start_category, :category)
  fab!(:next_category, :category)
  fab!(:step_1) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: start_category.id,
      position: 1,
      name: "Triage",
    )
  end
  fab!(:step_2) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: next_category.id,
      position: 2,
      name: "Review",
    )
  end
  fab!(:option_accept) do
    Fabricate(:workflow_option, slug: "accept", name: "Accept")
  end
  fab!(:step_option) do
    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: option_accept.id,
      target_step_id: step_2.id,
      position: 1,
    )
  end
  fab!(:topic) { Fabricate(:topic_with_op, category: start_category, user: actor) }
  fab!(:workflow_state) do
    Fabricate(
      :workflow_state,
      topic_id: topic.id,
      workflow_id: workflow.id,
      workflow_step_id: step_1.id,
    )
  end

  before do
    enable_current_plugin
    SiteSetting.workflow_enabled = true
    GroupUser.create!(group_id: actor_group.id, user_id: actor.id)

    start_category.set_permissions(everyone: :readonly, actor_group.id => :full, staff: :full)
    next_category.set_permissions(everyone: :readonly, actor_group.id => :full, staff: :full)
    start_category.save!
    next_category.save!
  end

  it "exposes transition target metadata on the topic model" do
    sign_in(actor)
    page.visit(topic.relative_url)

    actions =
      page.evaluate_script(
        "Discourse.__container__.lookup('controller:topic').model.workflow_step_actions",
      )

    expect(actions.first["target_step_name"]).to eq(step_2.name)
  end

  it "exposes transition permission state for users without category topic-create access" do
    sign_in(viewer)
    page.visit(topic.relative_url)

    can_act =
      page.evaluate_script(
        "Discourse.__container__.lookup('controller:topic').model.workflow_can_act",
      )

    expect(can_act).to eq(false)
  end

  it "exposes when the current workflow step was entered" do
    workflow_state.update_columns(updated_at: 3.days.ago)
    sign_in(actor)
    page.visit(topic.relative_url)

    entered_at =
      page.evaluate_script(
        "Discourse.__container__.lookup('controller:topic').model.workflow_step_entered_at",
      )

    expect(Time.zone.parse(entered_at)).to be < 2.days.ago
  end
end
