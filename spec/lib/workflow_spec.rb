# frozen_string_literal: true

require_relative "../plugin_helper"

describe DiscourseWorkflow::Workflow do
  it "keeps slug stable when updating non-name attributes" do
    workflow = Fabricate(:workflow, name: "Stable Slug Workflow")
    original_slug = workflow.slug

    workflow.update!(description: "updated description")

    expect(workflow.reload.slug).to eq(original_slug)
  end

  it "is kanban compatible for a connected workflow" do
    workflow = Fabricate(:workflow, name: "Kanban Compatible")
    step_1 = Fabricate(:workflow_step, workflow_id: workflow.id, position: 1)
    step_2 = Fabricate(:workflow_step, workflow_id: workflow.id, position: 2)
    option = Fabricate(:workflow_option, slug: "next")
    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: option.id,
      target_step_id: step_2.id,
    )

    expect(workflow.kanban_compatible?).to eq(true)
  end

  it "is kanban compatible when there is a cycle through backward transitions" do
    workflow = Fabricate(:workflow, name: "Kanban Cycle")
    step_1 = Fabricate(:workflow_step, workflow_id: workflow.id, position: 1)
    step_2 = Fabricate(:workflow_step, workflow_id: workflow.id, position: 2)
    option_1 = Fabricate(:workflow_option, slug: "next")
    option_2 = Fabricate(:workflow_option, slug: "back")
    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: option_1.id,
      target_step_id: step_2.id,
    )
    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_2.id,
      workflow_option_id: option_2.id,
      target_step_id: step_1.id,
    )

    expect(workflow.kanban_compatible?).to eq(true)
  end

  it "is not kanban compatible when a directed edge has multiple options" do
    workflow = Fabricate(:workflow, name: "Kanban Duplicate Directed Edge")
    step_1 = Fabricate(:workflow_step, workflow_id: workflow.id, position: 1)
    step_2 = Fabricate(:workflow_step, workflow_id: workflow.id, position: 2)
    option_1 = Fabricate(:workflow_option, slug: "next")
    option_2 = Fabricate(:workflow_option, slug: "skip")

    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: option_1.id,
      target_step_id: step_2.id,
    )
    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: option_2.id,
      target_step_id: step_2.id,
    )

    expect(workflow.kanban_compatible?).to eq(false)
  end

  it "is not kanban compatible when steps are disconnected from start" do
    workflow = Fabricate(:workflow, name: "Kanban Disconnected")
    Fabricate(:workflow_step, workflow_id: workflow.id, position: 1)
    Fabricate(:workflow_step, workflow_id: workflow.id, position: 2)

    expect(workflow.kanban_compatible?).to eq(false)
  end
end
