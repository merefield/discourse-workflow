# frozen_string_literal: true

require_relative "../plugin_helper"

describe DiscourseWorkflow::WorkflowSerializer do
  fab!(:admin)
  fab!(:workflow) { Fabricate(:workflow, name: "Serializer Workflow") }
  fab!(:category_1, :category)
  fab!(:category_2, :category)
  fab!(:step_1) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: category_1.id,
      position: 1,
    )
  end
  fab!(:step_2) do
    Fabricate(
      :workflow_step,
      workflow_id: workflow.id,
      category_id: category_2.id,
      position: 2,
    )
  end

  it "serializes workflow step count and boundary categories from workflow_steps" do
    serializer = described_class.new(workflow, scope: Guardian.new(admin))

    expect(serializer.workflow_steps_count).to eq(2)
    expect(serializer.starting_category_id).to eq(category_1.id)
    expect(serializer.final_category_id).to eq(category_2.id)
    expect(serializer.kanban_compatible).to eq(false)
    expect { serializer.as_json }.not_to raise_error
  end

  it "serializes kanban compatibility when the workflow graph is compatible" do
    option = Fabricate(:workflow_option, slug: "next", name: "Next")
    Fabricate(
      :workflow_step_option,
      workflow_step_id: step_1.id,
      workflow_option_id: option.id,
      target_step_id: step_2.id,
    )

    serializer = described_class.new(workflow, scope: Guardian.new(admin))

    expect(serializer.kanban_compatible).to eq(true)
  end
end
