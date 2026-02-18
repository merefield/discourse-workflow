# frozen_string_literal: true

require_relative "../plugin_helper"

describe DiscourseWorkflow::Workflow do
  it "keeps slug stable when updating non-name attributes" do
    workflow = Fabricate(:workflow, name: "Stable Slug Workflow")
    original_slug = workflow.slug

    workflow.update!(description: "updated description")

    expect(workflow.reload.slug).to eq(original_slug)
  end
end
